package com.github.ferstl.doclet

import java.io.StringReader
import java.io.Writer
import java.util.List
import java.util.regex.Pattern
import org.eclipse.xtext.xbase.lib.Pair

import static extension com.github.ferstl.doclet.MarkdownExtensions.*
import static extension org.apache.commons.io.IOUtils.*
import static extension org.apache.commons.lang3.StringUtils.*

class MarkdownExtensions {
  static val LINE_SEPARATOR = System::getProperty('line.separator', '\n')
  static val EXTERNAL_MEMBER_LINK = Pattern::compile('\\{@link ([\\w_]+?)#(set)?([\\w_]+?)(\\(.*?\\))?\\}');
  static val CLASS_LINK = Pattern::compile('\\{@link ([\\w_]+?)\\}');
  static val INTERNAL_MEMBER_LINK = Pattern::compile('\\{@link #(set)?([\\w_]+?)(\\(.*?\\))?\\}');
  
  static val HTML_TAG_REPLACEMENTS = newHashMap(
    new Pair('code', '`'), new Pair('em', '*'), new Pair('strong', '**'), new Pair('pre', '')
  )
  
  
  def static processText(String text, (String)=>String... processFunctions) {
    var result = text
    for (func : processFunctions) {
      result = func.apply(result)
    }
    result
  }
  
  def static processText(
    String text, List<String> classnames, (String, List<String>)=>String... processFunctions) {
    var result = text
    for (func : processFunctions) {
      result = func.apply(text, classnames)
    }
    result
  }
  
  def static processExternalMemberLink(String text, List<String> classnames) {
    val matcher = EXTERNAL_MEMBER_LINK.matcher(text);
    val sb = new StringBuffer
    while (matcher.find) {
      val classname = matcher.group(1)
      var membername = matcher.group(3)
      // The poor man's way of recognizing constants
      if (!membername.matches('[A-Z_]*')) {
        membername = membername.uncapitalize
      }
      if (classnames.contains(classname)) {
        matcher.appendReplacement(sb, '''[«classname».«membername»](«classname»)''')
      } else {
        matcher.appendReplacement(sb, '''`«classname».«membername»`''')
      }
    }
    matcher.appendTail(sb)
    sb.toString
  }
  
  def static processClassLink(String text, List<String> classnames) {
    val matcher = CLASS_LINK.matcher(text);
    val sb = new StringBuffer
    while (matcher.find) {
      val classname = matcher.group(1)
      if (classnames.contains(classname)) {
        matcher.appendReplacement(sb, '''[«classname»](«classname»)''')
      } else {
        matcher.appendReplacement(sb, '''`«classname»`''')
      }
    }
    matcher.appendTail(sb)
    sb.toString
  }
  
  def static processInternalMemberLink(String text) {
    val matcher = INTERNAL_MEMBER_LINK.matcher(text);
    val sb = new StringBuffer
    while (matcher.find) {
      val membername = matcher.group(2).uncapitalize
      matcher.appendReplacement(sb, '''`«membername»`''')
    }
    matcher.appendTail(sb)
    sb.toString
  }
  
  def static processHtmlTags(String text) {
    var result = text
    for (entry : HTML_TAG_REPLACEMENTS.entrySet) {
      val opening = '''<«entry.key»>'''.toString
      val closing = '''</«entry.key»>'''.toString
      result = result.replaceAll(opening, entry.value)
      result = result.replaceAll(closing, entry.value)
    }
    result
  }
  
  def static processLeadingWhitespace(String text) {
    val reader = new StringReader(text)
    val lines = reader.readLines
    lines.join(LINE_SEPARATOR, [s | s.startsWith(' ')
      if (s.startsWith(' ')) {
        s.substring(1, s.length)
      } else {
        s
      }
    ])
  }
  
  def static toMarkdown(String text, List<String> classnames) {
    text.processText(
      [processClassLink(it, classnames)],
      [processExternalMemberLink(it, classnames)],
      [processInternalMemberLink(it)],
      [processHtmlTags(it)],
      [processLeadingWhitespace(it)]
    )
  }
  
  def static toSingleLineMarkdown(String text, List<String> classnames) {
    val reader = new StringReader(text.toMarkdown(classnames))
    // read all lines, remove empty strings, trim and join
    (reader.readLines => [remove('')]).join(' ', [s | s.trim])
  }
  
  def static println(Writer writer, String text) {
    writer.write(text + LINE_SEPARATOR)
    writer
  }
  
  def static printTableHeader(Writer writer, CharSequence... headerCols) {
    val header = '''
    | «headerCols.join(' | ')» |
    «FOR col : headerCols BEFORE '|' SEPARATOR '|' AFTER '|'»:«'-'.repeat(col.length + 1)»«ENDFOR»'''
    writer.println(header.toString)
  }
  
  def static printTableLine(Writer writer, CharSequence... columns) {
    writer.println('''| «columns.join(' | ')» |'''.toString)
  }
}