package com.github.ferstl.doclet

import java.io.StringWriter
import org.junit.Test

import static extension com.github.ferstl.doclet.MarkdownExtensions.*

class MarkdownExtensionsTest {
  
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
