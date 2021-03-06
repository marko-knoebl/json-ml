# Dependencies
htmlparser2= require 'htmlparser2'
cheerio= require 'cheerio'

htmlBeautify= require('js-beautify').html

# Public
class JsonML
  stringifyListMode: on
  stringify: (object,replacer,indent)->
    html= ''
    if @stringifyListMode
      html+= @stringifyElement element,replacer for element in object
    else
      html+= @stringifyElement object,replacer

    if indent>0
      html= htmlBeautify html,
        indent_size: indent
        unformatted: ['code','pre','em','strong','span']
      html= html
        .replace /^\s*/g, ''
        .replace /(\r\n|\n){2,}/g,'\n'

    html

  stringifyElement: (element,replacer)->
    if typeof element is 'string'
      node= element
    else
      unless typeof element[0] is 'string'
        throw new TypeError 'Invalid tagName "'+element[0]+'"'

      name= element.shift()
      attributes= element.shift() if element[0]?.toString() is '[object Object]'
      elementList= element ? []

      node= cheerio '<'+name+'/>'
      node.attr attributes if attributes?
      node.append @stringifyElement list for list,i in elementList

    node= replacer node if replacer?

    node
    
  parse: (html,trim=yes)->
    nodes= htmlparser2.parseDOM html,{xmlMode:on}
    object= @parseElementList nodes,trim
    object

  parseElementList: (nodes,trim=yes)->
    i= -1

    elementList= []
    for node in nodes
      element= @parseElement node,trim
      if typeof element is 'string'
        element= element.trim() if trim
        element= '' if element is '&nbsp;' and trim
        
      continue if element?.length is 0

      canConcat= typeof elementList[i] is 'string' and typeof element is 'string'
      if canConcat
        elementList[i]+= element
      else
        elementList.push element if element?
        i++

    elementList

  parseElement: (node,trim=yes)->
    {type,data,name,attribs,children}= node

    switch type
      when 'directive' then '<'+data+'>'
      when 'comment' then '<!--'+data+'-->'
      when 'text' then data
      when 'tag','script','style'
        elementList= @parseElementList children,trim

        element= []
        element.push name if name?
        element.push attribs if Object.keys(attribs).length
        element.push child for child in elementList
        element

      else
        throw new TypeError type+' is Invalid node type'

module.exports= new JsonML
module.exports.JsonML= JsonML
