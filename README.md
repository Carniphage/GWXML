# GWXML
A lightweight Swift XML Parser

This is intended to be a simple to use XML parser for Swift. 
It is not a wrapper around NSXML, but native code.

It is closely based on TBXML 
[http://www.tbxml.co.uk/TBXML/TBXML_Free.html]

To use.
Just include this file in your project. 
A framework for this little code seems like overkill.

The content of the file is divided into XMLElement(s) and XMLAttribute(s).
XMLElement is an object
XMLAttribute is a struct


To parse an XML file in the app bundle

`let xmlRootElement:XMLElement = GWXML(bundleFile:"example.xml").rootElement`


to get an element name, or text
  
  `let name = element.name`
  `let text = element.text    //returns swift string`
  
  
to iterate through childen

`for child in element.children
  {
    ...    
  }`

to iterate through attributes
  
`for attribute in element.attributes
{
        let attributeName = attribute.name
        let attributeValue = attribute.value
}`

to find value of named attribute

  `let widthValue:String? = element.valueOfAttributeNamed("width")`

to find named child element
 
    `floatElement = element.childElementNamed("float_array")`




