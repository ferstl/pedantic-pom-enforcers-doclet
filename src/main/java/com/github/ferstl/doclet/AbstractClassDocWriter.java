package com.github.ferstl.doclet;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;

import com.sun.javadoc.ClassDoc;

/**
 * Abstract implementation of a writer for {@link ClassDoc} elements. It is implemented in Java
 * because Xtend does not support &quot;try with resources&quot;.
 */
public abstract class AbstractClassDocWriter {

  private final Charset encoding;
  private final Path outputDirectory;
  private final ClassDoc clazz;
  private final String filename;

  public AbstractClassDocWriter(
      Charset encoding, Path outputDirectory, String filename, ClassDoc clazz) {
    this.encoding = encoding;
    this.outputDirectory = outputDirectory;
    this.clazz = clazz;
    this.filename = filename;
  }

  public final void write() throws IOException {
    File target = new File(this.outputDirectory.toFile(), this.filename);

    try (Writer writer = Files.newBufferedWriter(target.toPath(), this.encoding)) {
      writeDoc(writer, this.clazz);
    }
  }

  protected abstract void writeDoc(Writer writer, ClassDoc clazz) throws IOException;
}
