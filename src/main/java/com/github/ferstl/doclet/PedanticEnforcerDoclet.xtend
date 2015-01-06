package com.github.ferstl.doclet

import com.sun.javadoc.ClassDoc
import com.sun.javadoc.Doc
import com.sun.javadoc.DocErrorReporter
import com.sun.javadoc.RootDoc
import com.sun.javadoc.Tag
import java.io.File
import java.io.Writer
import java.nio.charset.Charset
import java.nio.file.Path
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

import static extension java.nio.file.Files.*
import static extension org.apache.commons.lang3.StringUtils.*
import static extension com.github.ferstl.doclet.MarkdownExtensions.*

class PedanticEnforcerDoclet {
  
  static val OPT_OUTPUT_DIR = "-outputDirectory"
  static val OPT_ENCODING = "-encoding"
  static val CLASS_PATTERN = "(Compound)?Pedantic.*Enforcer"
  
  static var Path outputDirectory
  static var Charset encoding

  // Define the length of each option (doclet method)
  def static int optionLength(String option) {
    switch option {
      case OPT_OUTPUT_DIR: 2
      case OPT_ENCODING: 2
      default: 0
    }
  }
  
  // Process the options (doclet method)
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
  
  // Doclet main
  def static boolean start(RootDoc root) {
    // create the output directory if it doesn't exist
    outputDirectory.createDirectories
    
    // get the classes to be documented
    val overviewClass = root.classes.findFirst[simpleTypeName.equals("PedanticEnforcerRule")]
    val classes = root.classes.filter[simpleTypeName.matches(CLASS_PATTERN)].toList
    val classnames = new ArrayList(classes.map[simpleTypeName].toList)
    classnames.add("PedanticEnforcerRule")
    
    // Write the overview page
    new OverviewWriter(encoding, outputDirectory, overviewClass, classnames).write
    
    // Write the enforcer rule documentation
    classes.forEach[c |
      new EnforcerRuleWriter(encoding, outputDirectory, c, classnames).write
    ]
    
    true
  }
}

abstract class AbstractMarkdownWriter extends AbstractClassDocWriter {
  
  val List<String> classnames
  
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz.simpleTypeName + '.md', clazz)
    this.classnames = classnames
  }
  
  def protected getClassnames() {
    classnames
  }
}

class OverviewWriter extends AbstractMarkdownWriter {
  
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz, classnames)
  }
  
  override protected writeDoc(Writer writer, ClassDoc clazz) {
    writer => [
      writer.println(clazz.commentText.toMarkdown(classnames))
      writer.println('')
      printTableHeader("Enforcer", "ID", "Description")
      // The CompoundPedanticEnforcer does not have an ID. So we have to hardcode the table entry
      printTableLine(
      "[CompoundPedanticEnforcer](CompoundPedanticEnforcer)",
      "n/a", "Used to aggregate several pedantic enforcer rules.")
    ]
    
    clazz.fields.forEach[
      if (seeTags.head != null) {
          val refClass = seeTags.head.referencedClass
          val refType = refClass.simpleTypeName
          val description = refClass.firstSentenceTags.head.text
          
          writer.printTableLine('''[«refType»](«refType»)''', name, description.toSingleLineMarkdown(classnames))
      }
    ]
  }
}

class EnforcerRuleWriter extends AbstractMarkdownWriter {
  new(Charset encoding, Path outputDirectory, ClassDoc clazz, List<String> classnames) {
    super(encoding, outputDirectory, clazz, classnames)
  }

  override protected writeDoc(Writer writer, ClassDoc clazz) {
    val enforcerId = clazz.tags.findFirst['@id' == name].text.defaultIfBlank('N/A')
    val since = clazz.tags.findFirst['@since' == name].text.defaultIfBlank('');
    
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
      writer.println('''#### ID: «enforcerId.processExternalMemberLink(classnames)»''')
      writer.println('''«since.since»''')
      writer.println('')
      writer.println(clazz.commentText.toMarkdown(classnames))
      writer.println('')
      writer.println('### Configuration Options')
      writer.println('')
      printTableHeader('Option', 'Default', 'Description')
      configPrameters.forEach[
        writer.printTableLine(
            '''`«name»`''',
            defaultValue.toSingleLineMarkdown(classnames),
            '''«description.toSingleLineMarkdown(classnames)» «since.since»''')
      ]
      writer.println('')
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
        val since = tags.findFirst['@since' == name].text.defaultIfBlank('')
        val description = configTag.holder.commentText.toSingleLineMarkdown(classnames)
        func.apply(new ConfigurationParameter(paramName, defaultValue, description, since))
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
  val String since
}