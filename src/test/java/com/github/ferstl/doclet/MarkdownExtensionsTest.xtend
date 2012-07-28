package com.github.ferstl.doclet

import java.io.StringWriter
import org.junit.Test

import static extension com.github.ferstl.doclet.MarkdownExtensions.*
import static extension org.junit.Assert.*

class MarkdownExtensionsTest {
  
  @Test
  def void tableHeader() {
    val writer = new StringWriter
    writer.printTableHeader("foo", "bar", "baz")
    val expected =
      '''
      | foo | bar | baz |
      |:----|:----|:----|
      '''.toString
    expected.assertEquals(writer.toString)
  }
  
  @Test
  def void externalMemberLink() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text =
      '''
      Bla bla bla {@link Foo#fooMember} bla bla bla {@link Bar#setBarMember} blablabla
      bla bla {@link UnknownClass#someMember} {@link #internalMember} {@link SomeClass}.
      '''.toString
    val expected =
      '''
      Bla bla bla [Foo.fooMember](Foo) bla bla bla [Bar.barMember](Bar) blablabla
      bla bla `UnknownClass.someMember` {@link #internalMember} {@link SomeClass}.
      '''.toString
    expected.assertEquals(text.toString.processExternalMemberLink(classes))
  }
  @Test
  def void classLink() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text =
      '''
      Bla bla bla {@link Foo} bla bla bla {@link Bar} blablabla
      bla bla {@link UnknownClass} {@link Bar#externalMember} {@link SomeClass}.
      '''.toString
    val expected =
      '''
      Bla bla bla [Foo](Foo) bla bla bla [Bar](Bar) blablabla
      bla bla `UnknownClass` {@link Bar#externalMember} `SomeClass`.
      '''.toString
    expected.assertEquals(text.toString.processClassLink(classes))
  }
  @Test
  def void internalMemberLink() {
    val text =
      '''
      Bla bla bla {@link #fooMember} bla bla bla {@link #setBarMember} blablabla
      bla bla {@link #someMember}.
      '''.toString
    val expected =
      '''
      Bla bla bla `fooMember` bla bla bla `barMember` blablabla
      bla bla `someMember`.
      '''.toString
    expected.assertEquals(text.toString.processInternalMemberLink)
  }
  
  @Test
  def void htmlTags() {
    val text = 'Bla bla bla <code>foo</code> bla <em>important</em> bla bla'
    val expected = 'Bla bla bla `foo` bla *important* bla bla'
    expected.assertEquals(text.processHtmlTags)
  }
  
  @Test
  def void singleLineMarkdown() {
    val classes = newArrayList("Foo", "Bar", "Baz");
    val text =
      '''
      Bla bla bla {@link #fooMember} {@link #setBarMember} {@link #someMember} {@link SomeClass}
      {@link Bar} <code>someCode</code> bla bla bal bla
      <pre>
           bla bla bla
      </pre>
      <em>important</em> bla bla bla <strong>even more important</strong>
      '''.toString
    val expected = 'Bla bla bla `fooMember` `barMember` `someMember` `SomeClass` [Bar](Bar) `someCode` ' 
                 + 'bla bla bal bla bla bla bla  *important* bla bla bla **even more important**'
    expected.assertEquals(text.toSingleLineMarkdown(classes))
  }
}
