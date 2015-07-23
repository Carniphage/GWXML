//
//  GWXML.swift
//
//  A small and simple XML Dom parser written in Swift
//  Inspired by TBXML 
//  Glyn Williams - 2015
//
//  How to use....
// 
//  To parse a file in the bundle
//
//  let xmlRootElement = GWXML(bundleFile:"example.xml").rootElement
//  
//  to get an element name, or text
//  
//  let name = element.name
//  let text = element.text
//
//  to iteerate through childen
//  for child in attribute.children
//  {
//      
//  }
//
//  to iterate through attributes
//  
//  for attribute in element.attributes
//  {
//        let attributeName = attribute.name
//        let attributeValue = attribute.value
//  }
//
//  to find value of named attribue
//
//  let width:String? = element.valueOfAttributeNamed("width")
//

//  Todo 
// We should make this a "throws" type action - if the XML is malformed in some way


import Foundation


//Attributes are simple name / value pairs
public struct XMLAttribute
{
    let name:String
    let value:String
    

    init(name:String,value:String)
    {
        self.name = name
        self.value = value
    }
    
    func list()
    {
       print(" ( \(name) = \"\(value)\" )") 
    }

}



// XMLElement - 

public class XMLElement
{
   	var name:String = ""
    var text:String? = nil
    var children:[XMLElement] = []
    var attributes:[XMLAttribute] = []
    
    //no constructor yet
    
    public func childElementNamed(name:String) -> XMLElement?
    {
        for child in children
        {
            if child.name == name
            {
                return child
            }
        }
        return nil
    }
    
    
    public func valueOfAttributeNamed(name:String) -> String?
    {
        for attribute in attributes
        {
            if attribute.name == name
            {
                return attribute.value
            }
        }
        return nil
    }
    
    
    
    //list prints the tree for debugging purposes
    public func list(depth:Int)         //list out the XML graph as text
    {
        func printSpaces(count:Int)
        {
            for var i = 0 ; i < count ; i++
            {
                print("  ", appendNewline: false)
            }
        }
        
        printSpaces(depth)
        if let text = text
        {
            print("< \(name) : \(text) >")
        }
        else
        {
            print("< \(name) >")
        }
        
        for attribute in attributes
        {
            printSpaces(depth)
            attribute.list()
        }
        for child in children
        {
            child.list(depth + 1)
        }
    }
}



//This class puts the parse functionality into a standalone class. But it could be placed into element?
public class GWXML
{
    
    typealias BytePointer = UnsafeMutablePointer<Int8>         //this looks less scary

    
    //should make this comply to the error protocol.
    public enum XMLError
    {
        case NO_ERROR
        case DATA_NIL
        case DECODE_FAILURE
        case MEMORY_ALLOC_FAILURE
        case FILE_NOT_FOUND_IN_BUNDLE
        case ELEMENT_IS_NIL
        case ELEMENT_NAME_IS_NIL
        case ATTRIBUTE_IS_NIL
        case ATTRIBUTE_NAME_IS_NIL
        case ELEMENT_TEXT_IS_NIL
        case PARAM_NAME_IS_NIL
        case ATTRIBUTE_NOT_FOUND
        case ELEMENT_NOT_FOUND
        case UNMATCHED_ELEMENTS
        
        //TODO: Write this
        func asString()->String
        {
            return "XML Error"
        }
    }

    
    enum XMLFragmentType
    {
        case ElementStart
        case ElementEnd
        case SelfClosingElement
        case CommentElement
        case CDataElement          //CData content - not supported yet
        case SyntaxError
    }
    
    
    //Common Ascii hardcoded values
    enum ASCII
    {
        static let space:Int8 = 32              //notice this is not really an enum but just a namespace
        static let exclamation:Int8 = 33
        static let question:Int8 = 63
        static let slash:Int8 = 47
        static let backslash:Int8 = 92
        static let quotes:Int8 = 34
        static let quote:Int8 = 39
        static let equals:Int8 = 61
        static let leftAngle:Int8 = 60
        static let rightAngle:Int8 = 62
        static let rightSquare:Int8 = 93
        
    }
    
    //make this an enum
    
    
    
    public var rootElement:XMLElement? = nil
    public var error:XMLError = .NO_ERROR
    
    
    //This should throw
    public init(data:NSData?)
    {
        if let data = data
        {
            let startPointer:BytePointer = UnsafeMutablePointer<Int8>(data.bytes)
            let endPointer:BytePointer = startPointer + data.length - 1
            var readPointer:BytePointer = nil
            var element:XMLElement?
            (element,error) = scanXMLBlock(startPointer,endPointer,&readPointer)
            if error != .NO_ERROR
            {
                print("GWXML Error:\(error.asString())")                        
            }
            else
            {
                self.rootElement = element
            }
        }
        error = .DATA_NIL
        print("GWXML Error:\(error.asString())")                        
    }
    
    
    //this should throw
    public convenience init(bundleFile:String)
    {
        if let bundleResourcePath = NSBundle.mainBundle().resourcePath
        {
            let path = bundleResourcePath + "/" + bundleFile
            //let url = NSURL(fileURLWithPath: path)
            if let data = NSData(contentsOfFile: path)
            {
                self.init(data:data)
                return
            }
            
        }
        self.init(data:nil)
    }
    
    
    
    //This is a recursive function. 
    //This should throw
    func scanXMLBlock(startPointer:BytePointer, _ endPointer:BytePointer, inout _ readPointer:BytePointer) -> (XMLElement?,XMLError)
    {
        //let blockStart = blockPointer
        var element:XMLElement? = nil
        readPointer = startPointer
        var error:XMLError = .NO_ERROR
        var elementStartEndPointer:BytePointer = nil
        
        //TODO:check if there is more content
        
        var isElementComplete:Bool = false
        
        repeat 
        {
            var fragEndPointer:BytePointer = nil
            let fragStartPointer = readPointer
            let fragType = scanFragment(readPointer,endPointer,&fragEndPointer)
            
            switch fragType
            {
            case .ElementStart:
                
                if let element = element
                {
                    //if we already have built an element. Add these as children
                    let childStart = readPointer
                    var childEndPointer:BytePointer = nil
                    let (child,error) = scanXMLBlock(childStart, endPointer, &childEndPointer)
                    readPointer = childEndPointer + 1
                    if let child = child
                    {               
                        element.children.append(child)
                    }
                    elementStartEndPointer = nil        //if children no text
                }
                else
                {   
                    //create new node
                    elementStartEndPointer = fragEndPointer
                    element = XMLElement()      //new element
                    if let element = element
                    {
                        let nameStartPointer = strstr(fragStartPointer,"<") + 1
                        var nameEndPointer:BytePointer = nil
                        element.name = parseName(nameStartPointer,fragEndPointer,&nameEndPointer)
                        //println("New <\(element.name)>")
                        
                        let attributeStartPointer = nameEndPointer + 1
                        var attributeEndPointer:BytePointer = nil

                        element.attributes = parseAttributes(attributeStartPointer,fragEndPointer,&attributeEndPointer)
                        //scan attributes here
                        
                        //test for self closing xml here
                        if (fragEndPointer - 1).memory == ASCII.slash
                        {
                            isElementComplete = true
                        }
                    
                    }
                    
                    
                    readPointer = fragEndPointer + 1
                    
                }
                
            case .ElementEnd:
                if let element = element
                {
                    if elementStartEndPointer != nil
                    {
                        let textStartPointer = elementStartEndPointer + 1
                        let elementEndStartPointer = strstr(fragStartPointer,"<")
                        elementEndStartPointer.memory = 0
                        if let text = String.fromCString(textStartPointer) 
                        {
                            element.text = text 
                        }
                    }
                    
                    isElementComplete = true
                    readPointer = fragEndPointer + 1
                    
                }
                else
                {
                    error = .DECODE_FAILURE
                    isElementComplete = true
                }
                
            case .CDataElement:
                print("")
                
                
            case .CommentElement:
                readPointer = fragEndPointer + 1        //comment is skipped
                

            default:
                print("default")
                error = .DECODE_FAILURE
                isElementComplete = true
                readPointer = fragEndPointer + 1

                
            }
            
            
        } while !isElementComplete
        
        return (element,error)
    }

    
    //Little state machine to handle attribute parsing
    func parseAttributes(startPointer:BytePointer , _ endPointer:BytePointer , inout _ readPointer:BytePointer) -> [XMLAttribute]
    {
        
        enum XMLAttributeMode
        {
            case AttrNameStart
            case AttrNameEnd
            case AttrValueStart
            case AttrValueEnd
            //case TBXML_ATTRIBUTE_CDATA_END
        }
        
        var attributes:[XMLAttribute] = []
        var mode:XMLAttributeMode = .AttrNameStart
        var nameStart:BytePointer = nil
        var valueStart:BytePointer = nil
        var isSingleQuote:Bool = false
        
        for (var char = startPointer ; char <= endPointer ; char++)
        {
            switch (mode) 
            {
            case .AttrNameStart:
                if (char.memory != ASCII.space) 
                { 
                    nameStart = char;
                    mode = .AttrNameEnd
                }
                
            case .AttrNameEnd:
                if (char.memory == ASCII.space || char.memory == ASCII.equals) 
                {
                    char.memory = 0;
                    mode = .AttrValueStart;
                }
                
            case .AttrValueStart:
                if (char.memory != ASCII.space)
                {
                    if char.memory == ASCII.quotes || char.memory == ASCII.quote
                    {
                        valueStart = char+1;
                        mode = .AttrValueEnd;
                        isSingleQuote = ( char.memory == ASCII.quote)
                    }
                }
                
            case .AttrValueEnd:
                if (char.memory == ASCII.quotes && !isSingleQuote)  || ( char.memory == ASCII.quote && isSingleQuote)
                {
                    char.memory = 0;
                    
                    if let name = String.fromCString(nameStart)
                    {
                        if let value  = String.fromCString(valueStart)
                        {
                            let attribute = XMLAttribute(name:name,value:value)
                            attributes.append(attribute)
                        }
                    }
               
                    nameStart = nil;
                    valueStart = nil;
                    
                    // start looking for next attribute
                    mode = .AttrNameStart;
                }
                

            default:
                //syntax error
            print("error")
            
        }
        }

        return attributes
    }
    
    
    func parseName(startPointer:BytePointer , _ endPointer:BytePointer , inout _ readPointer:BytePointer) -> String
    {
        let nameEnd = strpbrk(startPointer," /\n>")
        readPointer = nameEnd
        nameEnd.memory = 0;
        if let name = String.fromCString(startPointer) 
        {
            return name
        }
        return ""
    }
    
    
    //determine what this fragment is
    func scanFragment(startPointer:BytePointer , _ endPointer:BytePointer , inout _ readPointer:BytePointer) -> XMLFragmentType
    {
        let elementStart = strstr(startPointer,"<")
        
        if (strncmp(elementStart,"<!--",4) == 0) 
        {
            //scan to the end
            readPointer = strstr(elementStart,"-->") + 3;
            return .CommentElement
        }
        
        let isCDATA:Int32 = strncmp(elementStart,"<![CDATA[",9)
        if isCDATA == 0
        {
            //currently this is not being handled
            //scan to the end
            return .CDataElement
        }
    
        let fragEndPointer = scanForElementEnd(elementStart + 1)
        
        let nameStartPointer = elementStart + 1
        
        if (nameStartPointer.memory == ASCII.question || nameStartPointer.memory == ASCII.exclamation)
        {
            readPointer = fragEndPointer
            return .CommentElement
        }
        
        if nameStartPointer.memory == ASCII.slash
        {
            readPointer = fragEndPointer
            return .ElementEnd
        }
    

        readPointer = fragEndPointer
        return .ElementStart
    }
    
    
    func scanForElementEnd(elementPointer:UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<Int8>
    {
        let pointer = strpbrk(elementPointer, "<>")
        return pointer
    }

}


