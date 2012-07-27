package com.github.ferstl.doclet;

import com.github.ferstl.doclet.MarkdownExtensions;
import java.io.StringWriter;
import java.util.ArrayList;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.InputOutput;
import org.junit.Test;

@SuppressWarnings("all")
public class MarkdownExtensionsTest {
  @Test
  public void tableHeader() {
    StringWriter _stringWriter = new StringWriter();
    final StringWriter writer = _stringWriter;
    MarkdownExtensions.printTableHeader(writer, "foo", "bar", "baz");
    InputOutput.<StringWriter>println(writer);
  }
  
  @Test
  public void externalMemberLink() {
    final ArrayList<String> classes = CollectionLiterals.<String>newArrayList("Foo", "Bar", "Baz");
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Bla bla bla {@link Foo#fooMember} bla bla bla {@link Bar#setBarMember} blablabla");
    _builder.newLine();
    _builder.append("bla bla {@link UnknownClass#someMember} {@link #internalMember} {@link SomeClass}.");
    _builder.newLine();
    final CharSequence text = _builder;
    String _string = text.toString();
    String _processExternalMemberLink = MarkdownExtensions.processExternalMemberLink(_string, classes);
    InputOutput.<String>println(_processExternalMemberLink);
  }
  
  @Test
  public void classLink() {
    final ArrayList<String> classes = CollectionLiterals.<String>newArrayList("Foo", "Bar", "Baz");
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Bla bla bla {@link Foo} bla bla bla {@link Bar} blablabla");
    _builder.newLine();
    _builder.append("bla bla {@link UnknownClass} {@link Bar#externalMember} {@link SomeClass}.");
    _builder.newLine();
    final CharSequence text = _builder;
    String _string = text.toString();
    String _processClassLink = MarkdownExtensions.processClassLink(_string, classes);
    InputOutput.<String>println(_processClassLink);
  }
  
  @Test
  public void internalMemberLink() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Bla bla bla {@link #fooMember} bla bla bla {@link #setBarMember} blablabla");
    _builder.newLine();
    _builder.append("bla bla {@link #someMember}.");
    _builder.newLine();
    final CharSequence text = _builder;
    String _string = text.toString();
    String _processInternalMemberLink = MarkdownExtensions.processInternalMemberLink(_string);
    InputOutput.<String>println(_processInternalMemberLink);
  }
  
  @Test
  public void htmlTags() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Bla bla bla <code>foo</code> bla bla bla");
    final CharSequence text = _builder;
    String _string = text.toString();
    String _processHtmlTags = MarkdownExtensions.processHtmlTags(_string);
    InputOutput.<String>println(_processHtmlTags);
  }
  
  @Test
  public void singleLineMarkdown() {
    final ArrayList<String> classes = CollectionLiterals.<String>newArrayList("Foo", "Bar", "Baz");
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Bla bla bla {@link #fooMember} {@link #setBarMember} {@link #someMember} {@link SomeClass}");
    _builder.newLine();
    _builder.append("{@link Bar} <code>someCode</code> bla bla bal bla");
    _builder.newLine();
    _builder.append("<pre>");
    _builder.newLine();
    _builder.append("     ");
    _builder.append("bla bla bla");
    _builder.newLine();
    _builder.append("</pre>");
    _builder.newLine();
    _builder.append("<em>important</em> bla bla bla <strong>even more important</strong>");
    _builder.newLine();
    final CharSequence text = _builder;
    String _string = text.toString();
    String _singleLineMarkdown = MarkdownExtensions.toSingleLineMarkdown(_string, classes);
    InputOutput.<String>println(_singleLineMarkdown);
  }
}
