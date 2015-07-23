# GWXML
A lightweight XML Parser for Swift
--------------------------------

This is intended to be a simple-to-use XML DOM-style parser for Swift. 
It is not a wrapper around NSXML.  
 
It is closely based on TBXML, and operates in an identical way
[http://www.tbxml.co.uk/TBXML/TBXML_Free.html]  
 
Usage
-----
Just include this file in your project. 
A framework for this little code seems like overkill  .

 
The content of the file is divided into XMLElement(s) and XMLAttribute(s).

* XMLElement is an object
* XMLAttribute is a struct  
 
 
To read an existing XML file in the app bundle

`let xmlRootElement:XMLElement = GWXML(bundleFile:"example.xml").rootElement`  

This returns a root element which is a parent to the entire XML document structure.
  
  
to get an element name, or text
  
  `let name = element.name    //returns swift string`
  `let text = element.text    //returns swift string`  
  
  
to iterate through childen

`for child in element.children` 
  `{ ` 
`    ... `   
 ` } v ` 
 

to iterate through attributes
  
`for attribute in element.attributes`
`{`
`        let attributeName = attribute.name`
`        let attributeValue = attribute.value`
`}`  

 
to find value of named attribute

` let widthValue:String? = element.valueOfAttributeNamed("width")`  

 
to find named child element
 
` floatElement = element.childElementNamed("float_array")` 

Optionals are used to indicate when finds are not successful. 



Notes
-----

So far the CDATA element is not supported.  
