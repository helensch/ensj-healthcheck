
package org.ensembl.healthcheck.test;

import java.io.File;

import junit.framework.Assert;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

import org.ensembl.healthcheck.util.ClassFileFilenameFilter;

/**
 * @version $Revision$
 * @author glenn
 */
public class ClassFileFilenameFilterTest extends TestCase {
  
  private ClassFileFilenameFilter cnff;
  private File file;
  
  public ClassFileFilenameFilterTest(java.lang.String testName) {
    super(testName);
  }
  
  public static void main(java.lang.String[] args) {
    junit.textui.TestRunner.run(suite());
  }
  
  public static Test suite() {
    TestSuite suite = new TestSuite(ClassFileFilenameFilterTest.class);
    
    return suite;
  }
  
  protected void setUp() {
    cnff = new ClassFileFilenameFilter();
    file = new File("");
  }
  
  /** Test of accept method, of class org.ensembl.healthcheck.util.ClassFileFilenameFilter. */
  public void testAccept() {
    
    System.out.println("testAccept");
    
    Assert.assertTrue(cnff.accept(file, "TestFile.class"));
    Assert.assertTrue(cnff.accept(file, "/work/ensjhealthcheck/org/ensembl/TestFile.class"));
    Assert.assertTrue(!cnff.accept(file, "TestFile.java"));
    Assert.assertTrue(!cnff.accept(file, "classes/file.xml"));

  }
  
  protected void tearDown() {
    
  }
  
  // Add test methods here, they have to start with 'test' name.
  // for example:
  // public void testHello() {}
  
  
  
}
