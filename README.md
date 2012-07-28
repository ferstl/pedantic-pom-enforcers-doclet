# Pedantic POM Enforcer Doclet
*- A doclet that generates the GitHub
[Wiki](https://github.com/ferstl/pedantic-pom-enforcers/wiki/PedanticEnforcerRule) pages for the
[Pedantic POM Enforcers](https://github.com/ferstl/pedantic-pom-enforcers)*

### Checkout
This project requires the Xtend runtime library and the Xtend Maven plugin which are both *not*
available on Maven central. They need to be downloaded from the Xtend Maven repository on
http://build.eclipse.org/common/xtend/maven/ .

In case you are using a repository manager like Nexus, you can simply configure a new repository.
Otherwise you need to add the repository directly to the POM file of this project:

    <repositories>
      <repository>
        <id>xtend</id>
        <url>http://build.eclipse.org/common/xtend/maven/</url>
      </repository>
    </repositories>
    <pluginRepositories>
      <pluginRepository>
        <id>xtend</id>
        <url>http://build.eclipse.org/common/xtend/maven/</url>
      </pluginRepository>
    </pluginRepositories>

Once the Xtend runtime and the Maven plugin is available, the doclet can be deployed or installed using
`mvn install` or `mvn deploy`.


### Generate the Wiki Pages
To generate the Wiki pages for the *Pedantic POM Enforcers*, the maven-javadoc-plugin has to be
configured as follows:

    <build>
      <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-javadoc-plugin</artifactId>
          <executions>
            <execution>
              <id>create-wiki</id>
              <goals>
                <goal>javadoc</goal>
              </goals>
              <configuration>
                <doclet>com.github.ferstl.doclet.PedanticEnforcerDoclet</doclet>
                <useStandardDocletOptions>false</useStandardDocletOptions>
                <additionalparam>-outputDirectory "${project.basedir}/../${project.artifactId}.wiki"</additionalparam>
                <docletArtifact>
                  <groupId>com.github.ferstl</groupId>
                  <artifactId>pedantic-pom-enforcers-doclet</artifactId>
                  <version>${pedantic-pom-enforcers-doclet.version}</version>
                </docletArtifact>
              </configuration>
            </execution>
          </executions>
        </plugin>
      </plugins>
    </build>

The POM file of the *Pedantic POM Enforcers* does already contain this configuration in a separate
Maven profile called `generate-wiki`. Running `mvn -Pgenerate-wiki javadoc:javadoc` will create the
Wiki in a directory called `pedantic-pom-enforcers.wiki`, which is also the name of the GIT
repository that contains the Wiki pages.