/*
 Copyright (C) 2003 EBI, GRL
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
package org.ensembl.healthcheck.testcase;

import org.ensembl.healthcheck.DatabaseRegistryEntry;

/**
 * Subclass of EnsTestCase for tests that apply to a <em>single</em> database. Such tests should
 * subclass <em>this</em> class and implement the <code>run</code> method.
 */
public abstract class SingleDatabaseTestCase extends EnsTestCase {

    /**
     * This method should be overridden by subclasses.
     * 
     * @param dbre
     *          The database to run on.
     * @return True if the test passed.
     */
    public abstract boolean run(DatabaseRegistryEntry dbre);

}
