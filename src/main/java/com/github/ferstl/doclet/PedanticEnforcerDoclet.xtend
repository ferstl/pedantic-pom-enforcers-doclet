package com.github.ferstl.doclet

import com.sun.javadoc.ClassDoc
import com.sun.javadoc.Doc
import com.sun.javadoc.DocErrorReporter
import com.sun.javadoc.RootDoc
import com.sun.javadoc.Tag
import java.io.File
import java.io.StringReader
import java.io.StringWriter
import java.io.Writer
import java.nio.charset.Charset
import java.nio.file.Path
import java.util.ArrayList
import java.util.List
import java.util.regex.Pattern
import org.eclipse.xtend.lib.Data
import org.eclipse.xtext.xbase.lib.Pair
import org.junit.Test

import static extension com.github.ferstl.doclet.AbstractMarkdownWriter.*
import static extension com.github.ferstl.doclet.PedanticEnforcerDoclet.*
import static extension java.nio.file.Files.*
import static extension org.apache.commons.io.IOUtils.*
import static extension org.apache.commons.lang3.StringUtils.*

class PedanticEnforcerDoclet {
  
  static val OPT_OUTPUT_DIR = "-outputDirectory"
  static val OPT_ENCODING = "-encoding"
  static val CLASS_PATTERN = "(Compound)?Pedantic.*Enforcer"
  
  static var Path outputDirectory
  static var Charset encoding

  def static int optionLength(String option) {
    switch option {
      case OPT_OUTPUT_DIR: 2
      case OPT_ENCODING: 2
      default: 0
    }
  }
  
  def static boolean validOptions(String[][] options, DocErrorReporter rep) {
    for (option : options) {
      switch option.get(0) {
        case OPT_OUTPUT_DIR: outputDirectory = new File(option.get(1)).toPath
        case OPT_ENCODING: encoding = Charset::forName(option.get(1))
      }
    }
    // ignore the other options
    return true
  }
  
  def static boolean start(RootDoc root) {
    // create the output directory if it doesn't exist
    outputDirectory.createDirectories
    
    // get the classes to be documented
    val overviewClass = root.classes.findFirst[simpleTypeName.equals("PedanticEnforcerRule")]
    val classes = root.classes.filter[simpleTypeName.matches(CLASS_PATTERN)].toList
    val classnames = new ArrayList(classes.map[simpleTypeName].toList)
    classnames.add("PedanticEnforcerRule")
    
    new OverviewWriter(encoding, outputDirectory, overviewClass, classnames).write
    
    classes.forEach[c |
      new EnforcerRuleWriter(encoding, outputDirectory, c, classnames).write
    ]
    
    return true
  }
  
  @Test
  def void tableHeader() {
    val writer = new StringWriter
    writer.printTableHeader("foo", "bar", "baz")
    println(writer)
  }
  
  @Test
  def void externalMemberLink() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text = '''
               Bla bla bla {@link Foo#fooMember} bla bla bla {@link Bar#setBarMember} blablabla
               bla bla {@link UnknownClass#someMember} {@link #internalMember} {@link SomeClass}.
               '''
    println(text.toString.processExternalMemberLink(classes))
  }
  @Test
  def void classLink() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text = '''
               Bla bla bla {@link Foo} bla bla bla {@link Bar} blablabla
               bla bla {@link UnknownClass} {@link Bar#externalMember} {@link SomeClass}.
               '''
    println(text.toString.processClassLink(classes))
  }
  @Test
  def void internalMemberLink() {
    val text = '''
               Bla bla bla {@link #fooMember} bla bla bla {@link #setBarMember} blablabla
               bla bla {@link #someMember}.
               '''
    println(text.toString.processInternalMemberLink)
  }
  
  @Test
  def void htmlTags() {
    val text = '''Bla bla bla <code>foo</code> bla bla bla'''
    println(text.toString.processHtmlTags)
  }
  
  @Test
  def void singleLineMarkdown() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text = '''
    Bla bla bla {@link #fooMember} {@link #setBarMember} {@link #someMember} {@link SomeClass}
    {@link Bar} <code>someCode</code> bla bla bal bla
    <pre>
         bla bla bla
    </pre>
    <em>important</em> bla bla bla <strong>even more important</strong>
    '''
    println(text.toString.toSingleLineMarkdown(classes))
  }
}

abstract class AbstractMarkdownWriter extends AbstractClassDocWriter {
  
  static val LINE_SEPARATOR = System::getProperty('line.separator', '\n')
  static val EXTERNAL_MEMBER_LINK = Pattern::compile('\\{@link ([\\w_]+?)#(set)?([\\w_]+?)(\\(.*?\\))?\\}');
  static val CLASS_LINK = Pattern::compile('\\{@link ([\\w_]+?)\\}');
  static val INTERNAL_MEMBER_LINK = Pattern::compile('\\{@link #(set)?([\\w_]+?)(\\(.*?\\))?\\}');
  
  static val HTML_TAG_REPLACEMENTS = newHashMap(
    new Pair('code', '`'), new Pair('em', '*'), new Pair('strong', '**'), new Pair('pre', '')
  )
  
  val List<String> classnames
  
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz.simpleTypeName + '.md', clazz)
    this.classnames = classnames
  }
  
  def getClassnames() {
    classnames
  }
  
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
//        matcher.appendReplacement(sb, '''[«classname».«membername»](«classname»)''')
        matcher.appendReplacement(sb, '''[«membername»](«classname»)''')
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
  
  def static println(Writer writer) {
    writer.write(LINE_SEPARATOR)
    writer
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

class OverviewWriter extends AbstractMarkdownWriter {
  
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz, classnames)
  }
  
  override protected writeDoc(Writer writer, ClassDoc clazz) {
    writer => [
      println(clazz.commentText.toMarkdown(classnames))
      // why does println without 'it.' not work!?
      it.println
      printTableHeader("Enforcer", "ID", "Description")
      printTableLine(
      "[CompoundPedanticEnforcer](CompoundPedanticEnforcer)",
      "n/a", "Used to aggregate several pedantic enforcer rules.")
    ]
    
    clazz.fields.forEach[
      val refClass = seeTags.head.referencedClass
      val refType = refClass.simpleTypeName
      val description = refClass.firstSentenceTags.head.text
      
      writer.printTableLine('''[«refType»](«refType»)''', name, description.toSingleLineMarkdown(classnames))
    ]
  }
}

class EnforcerRuleWriter extends AbstractMarkdownWriter {
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz, classnames)
  }

  override protected writeDoc(Writer writer, ClassDoc clazz) {
    val enforcerId = clazz.tags.findFirst['@id' == name].text.defaultIfBlank('N/A')
    
    // Collect all configuration parameters
    val List<ConfigurationParameter> configPrameters = newArrayList
    clazz => [
      val addFunction = [ConfigurationParameter p | configPrameters.add(p)]
      superclass.fields(false).extractConfigParameter(addFunction)
      superclass.methods.extractConfigParameter(addFunction)
      fields(false).extractConfigParameter(addFunction)
      methods.extractConfigParameter(addFunction)
    ]
    
    writer => [
      println('''#### ID: «enforcerId.processExternalMemberLink(classnames)»''')
      println(clazz.commentText.toMarkdown(classnames))
      println('')
      println('### Configuration Options')
      println('')
      printTableHeader('Option', 'Default', 'Description')
      configPrameters.forEach[
        writer.printTableLine(
            '''`«name»`''',
            defaultValue.toSingleLineMarkdown(classnames),
            description.toSingleLineMarkdown(classnames))
      ]
      println('')
    ]
  }
  
  def private extractConfigParameter(Doc[] docs, (ConfigurationParameter)=>Object func) {
     docs.forEach[
      val configTag = tags.findFirst['@configParam' == name]
      if (configTag != null) {
        var paramName = configTag.holder.name
        if (paramName.startsWith('set')) {
          paramName = paramName.removeStart('set').uncapitalize
        }
        val defaultValue = tags.findFirst['@default' == name].extractText('n/a')
        val description = configTag.holder.commentText.toSingleLineMarkdown(classnames)
        func.apply(new ConfigurationParameter(paramName, defaultValue, description))
      }
    ]
  }
  
  def private extractText(Tag tag, String defaultVal) {
    if (tag != null && !tag.text.blank) {
      tag.text
    } else {
      defaultVal
    }
  }
}

@Data class ConfigurationParameter {
  val String name
  val String defaultValue
  val String description
}