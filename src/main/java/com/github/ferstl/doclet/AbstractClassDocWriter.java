package com.github.ferstl.doclet;

import java.io.IOException;
import java.io.Writer;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;

import com.sun.javadoc.ClassDoc;

/**
 * Abstract implementation of a writer for {@link ClassDoc} elements. It is implemented in Java
 * because Xtend does not support &quot;try with resources&quot;.
 * See {@link https://bugs.eclipse.org/bugs/show_bug.cgi?id=366020}.
 */
public abstract class AbstractClassDocWriter {

  private final Charset encoding;
  private final ClassDoc clazz;
  private final Path targetFile;

  public AbstractClassDocWriter(Charset encoding, Path outputDirectory, String filename, ClassDoc clazz) {
    this.encoding = encoding;
    this.targetFile = outputDirectory.resolve(filename);
    this.clazz = clazz;
  }

  public final void write() throws IOException {
    try (Writer writer = Files.newBufferedWriter(this.targetFile, this.encoding)) {
      writeDoc(writer, this.clazz);
    }
  }

  protected abstract void writeDoc(Writer writer, ClassDoc clazz) throws IOException;
}
