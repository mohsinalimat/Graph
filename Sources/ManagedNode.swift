/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CoreData

internal class ManagedNode: ManagedModel {
    @NSManaged internal var nodeClass: NSNumber
    @NSManaged internal var type: String
    @NSManaged internal var createdDate: NSDate
    @NSManaged internal var propertySet: NSSet
    @NSManaged internal var groupSet: NSSet
    
    /// A reference to the Nodes unique ID.
    internal var id: String {
        var result: String?
        managedObjectContext?.performBlockAndWait { [unowned self] in
            do {
                try self.managedObjectContext?.obtainPermanentIDsForObjects([self])
            } catch {}
            result = String(stringInterpolationSegment: self.nodeClass) + self.type + self.objectID.URIRepresentation().lastPathComponent!
        }
        return result!
    }
    
    /// A reference to the groups.
    internal var groups: [String] {
        var g = [String]()
        managedObjectContext?.performBlockAndWait { [unowned self] in
            self.groupSet.forEach { (object: AnyObject) in
                if let group = object as? ManagedGroup {
                    g.append(group.name)
                }
            }
        }
        return g
    }
    
    /// A reference to the properties.
    internal var properties: [String: AnyObject] {
        var p = [String: AnyObject]()
        managedObjectContext?.performBlockAndWait { [unowned self] in
            self.propertySet.forEach { (object: AnyObject) in
                if let property = object as? ManagedProperty {
                    p[property.name] = property.object
                }
            }
        }
        return p
    }
    
    /**
     Initializer that accepts an identifier, a type, and a NSManagedObjectContext.
     - Parameter identifier: A model identifier.
     - Parameter type: A reference to the Entity type.
     - Parameter managedObjectContext: A reference to the NSManagedObejctContext.
     */
    internal convenience init(identifier: String, type: String, managedObjectContext: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(identifier, inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
        self.type = type
        createdDate = NSDate()
        propertySet = NSSet()
        groupSet = NSSet()
    }
    
    /// Deletes the relationships and actions before marking for deletion.
    internal override func delete() {
        managedObjectContext?.performBlockAndWait { [unowned self] in
            self.groupSet.forEach { [unowned self]  (object: AnyObject) in
                if let group = object as? ManagedGroup {
                    group.delete()
                    (self.groupSet as? NSMutableSet)?.removeObject(group)
                }
            }
            self.propertySet.forEach { [unowned self] (object: AnyObject) in
                if let property = object as? ManagedProperty {
                    property.delete()
                    (self.propertySet as? NSMutableSet)?.removeObject(property)
                }
            }
        }
        super.delete()
    }
    
    /**
     Access properties using the subscript operator.
     - Parameter name: A property name value.
     - Returns: The optional AnyObject value.
     */
    internal subscript(name: String) -> AnyObject? {
        var object: AnyObject?
        managedObjectContext?.performBlockAndWait { [unowned self] in
            for property in self.propertySet {
                if name == property.name {
                    object = property.object
                    return
                }
            }
        }
        return object
    }
    
    /**
     Adds the ManagedNode to the group.
     - Parameter name: The group name.
     - Returns: A boolean of the result, true if added, false
     otherwise.
     */
    internal func addToGroup(name: String) -> Bool {
        return false
    }
    
    /**
     Checks if the ManagedNode to a part group.
     - Parameter name: The group name.
     - Returns: A boolean of the result, true if a member, false
     otherwise.
     */
    internal func memberOfGroup(name: String) -> Bool {
        var result: Bool?
        managedObjectContext?.performBlockAndWait { [unowned self] in
            for group in self.groupSet {
                if name == group.name {
                    result = true
                    return
                }
            }
        }
        return result ?? false
    }
    
    /**
     Removes the ManagedNode from the group.
     - Parameter name: The group name.
     - Returns: A boolean of the result, true if removed, false
     otherwise.
     */
    internal func removeFromGroup(name: String) -> Bool {
        var result: Bool?
        managedObjectContext?.performBlockAndWait { [unowned self] in
            for group in self.groupSet {
                if name == group.name {
                    group.delete()
                    (self.groupSet as! NSMutableSet).removeObject(group)
                    result = true
                    return
                }
            }
        }
        return result ?? false
    }
}
