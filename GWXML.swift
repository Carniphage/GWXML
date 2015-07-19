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
        case ELEMENT_START
        case ELEMENT_END
        case SELF_CLOSING_ELEMENT
        case COMMENT_ELEMENT
        case CDATA_ELEMENT          //CData content - not supported yet
        case SYNTAX_ERROR
    }
    
    
    //make this an enum
    let spaceASCII:Int8 = 32
    let exclamationASCII:Int8 = 33
    let questionASCII:Int8 = 63
    let slashASCII:Int8 = 47
    let backslashASCII:Int8 = 92
    let quotesASCII:Int8 = 34
    let quoteASCII:Int8 = 39
    let equalsASCII:Int8 = 61
    let leftAngleASCII:Int8 = 60
    let rightAngleASCII:Int8 = 62
    let rightSquareASCII:Int8 = 93
    
    
    public var rootElement:XMLElement? = nil
    public var error:XMLError = .NO_ERROR
    
    
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
            case .ELEMENT_START:
                
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
                        if (fragEndPointer - 1).memory == slashASCII
                        {
                            isElementComplete = true
                        }
                    
                    }
                    
                    
                    readPointer = fragEndPointer + 1
                    
                }
                
            case .ELEMENT_END:
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
                
            case .CDATA_ELEMENT:
                print("")
                
                
            case .COMMENT_ELEMENT:
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

    
    func parseAttributes(startPointer:BytePointer , _ endPointer:BytePointer , inout _ readPointer:BytePointer) -> [XMLAttribute]
    {
        
        enum XMLAttributeMode
        {
            case ATTRIBUTE_NAME_START
            case ATTRIBUTE_NAME_END
            case ATTRIBUTE_VALUE_START
            case ATTRIBUTE_VALUE_END
            //case TBXML_ATTRIBUTE_CDATA_END
        }
        
        var attributes:[XMLAttribute] = []
        var mode:XMLAttributeMode = .ATTRIBUTE_NAME_START
        var nameStart:BytePointer = nil
        var valueStart:BytePointer = nil
        var isSingleQuote:Bool = false
        
        for (var char = startPointer ; char <= endPointer ; char++)
        {
            switch (mode) 
            {
            case .ATTRIBUTE_NAME_START:
                if (char.memory != spaceASCII) 
                { 
                    nameStart = char;
                    mode = .ATTRIBUTE_NAME_END
                }
            case .ATTRIBUTE_NAME_END:
                if (char.memory == spaceASCII || char.memory == equalsASCII) 
                {
                    char.memory = 0;
                    mode = .ATTRIBUTE_VALUE_START;
                }
            case .ATTRIBUTE_VALUE_START:
                if (char.memory != spaceASCII)
                {
                    if char.memory == quotesASCII || char.memory == quoteASCII
                    {
                        valueStart = char+1;
                        mode = .ATTRIBUTE_VALUE_END;
                        isSingleQuote = ( char.memory == quoteASCII)
                    }
                }
            case .ATTRIBUTE_VALUE_END:
                if (char.memory == quotesASCII && !isSingleQuote)  || ( char.memory == quoteASCII && isSingleQuote)
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
                    mode = .ATTRIBUTE_NAME_START;
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
            return .COMMENT_ELEMENT
        }
        
        let isCDATA:Int32 = strncmp(elementStart,"<![CDATA[",9)
        if isCDATA == 0
        {
            //currently this is not being handled
            //scan to the end
            return .CDATA_ELEMENT
        }
    
        let fragEndPointer = scanForElementEnd(elementStart + 1)
        
        let nameStartPointer = elementStart + 1
        
        if (nameStartPointer.memory == questionASCII || nameStartPointer.memory == exclamationASCII)
        {
            readPointer = fragEndPointer
            return .COMMENT_ELEMENT
        }
        
        if nameStartPointer.memory == slashASCII
        {
            readPointer = fragEndPointer
            return .ELEMENT_END
        }
    

        readPointer = fragEndPointer
        return .ELEMENT_START
    }
    
    
    func scanForElementEnd(elementPointer:UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<Int8>
    {
        let pointer = strpbrk(elementPointer, "<>")
        return pointer
    }

}


