  /*
  * Numenta Platform for Intelligent Computing (NuPIC)
  * Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
  * Numenta, Inc. a separate commercial license for this software code, the/  * following terms and conditions apply:
  *
  * This program is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License version 3 as
  * published by the Free Software Foundation.
  *
  * This program is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  * See the GNU General Public License for more details.
  *
  * You should have received a copy of the GNU General Public License
  * along with this program.  If not, see http://www.gnu.org/licenses.
  *
  * http://numenta.org/licenses/
  *
  */

import Foundation
/**
 SQLiteHelper is a collection of routines to help with SQL operations. It uses a simililar api to the android SQL interface
  */
open class SQLiteHelper {
    
    var dbQueue : FMDatabaseQueue
    var dateFormater: DateFormatter
    
    //Constant for conflict
    static let REPLACE = " REPLACE "
    
    /**  Delete the specified rows in table
    - parameter    whereClause : where clause with ? for subbed parameters
    - parameter    whereArgs : array of strings that will be subed for ?
    - returns: number of rows that have been removed
    
    */
    func delete (_ database: FMDatabase, table :String , whereClause: String?, whereArgs:[String]?)->Int32{
        
        
        var statement : String = "DELETE FROM " + table
        
        if (whereClause != nil ){
            statement += " where " + whereClause!;
        }
        if (database.executeUpdate(statement, withArgumentsIn: whereArgs)){
            return database.changes()
        }
        return 0
        
    }
    
    /** Prepare database for usage. Will execute the cmds specified in createDB.sql when the dB is created
        - parameter name : filename of the database. It will be created in the documents directory
   */
   public init(name: String){
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
        let docsDir = dirPaths[0]
        let databasePath = docsDir + "/"+name

        let checkValidation = FileManager.default
        let  exists = checkValidation.fileExists(atPath: databasePath)
    
    
        dbQueue = FMDatabaseQueue(path: databasePath as String)
    
        if (!exists){
            if let path = Bundle.main.path(forResource: "createdb", ofType:"sql") {
                do{
                    let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                    let commandList = data.components(separatedBy: CharacterSet (charactersIn: ";"))
                    
                    dbQueue.inDatabase() {
                        database in
                        
                            for cmd in commandList {
                              let success =  database?.executeUpdate(cmd, withArgumentsIn:nil)
                              if !success!{
                                    print ("Error creating table: " + (database?.lastErrorMessage())!)
                                }
                        }
                    }
  
           
                    } catch _ {
                        // What to do if we can't create tables?
                    }
            }
        }
    
        // Initialize date formatter object
        dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormater.timeZone = TimeZone(identifier:"UTC")
    }
    
    /** Start a database transaction
    */
  /*  func beginTransactionModeNonExclusive(){
        database.beginTransaction()
    }*/
    
    /** insert a row into the table
    - parameter table : tablename
    - parameter values: dictionary where the key is the column name
    - parameter conflictAlgorithm : How to handle conflicts
    - returns: id of row add, -1 for failure
    */
    func insertWithOnConflict(_ database: FMDatabase, table : String,  values :  Dictionary<String, AnyObject> ,  conflictAlgorithm : String) ->Int64{
        
        let statement =  prepareInsertStatement(table, columns: Array(values.keys), status : conflictAlgorithm)
        let rows =  database.executeUpdate(statement, withParameterDictionary: values )
        if (rows){
            return database.lastInsertRowId()
        }
   
        return -1
    }
    
    /** Update a row in a table
        needs to be implemented
    */
    func update(_ database: FMDatabase, table : String, values :  Dictionary<String, Any>,  whereClause : String,  whereArgs: [String])->Int64{
        return -1;
    }
    
    
    /** commit DB changes
    */
    func commit(){
      //  database.commit()
    }
    
    /** build an insert statement for use with a dictionary of parameters
     - parameter tableName : name of the table
     - parameter columns : columns
     - parameter status : on conflict clause
     - returns: sql string
   */
    func prepareInsertStatement(_ tableName: String , columns: [String], status: String)->String
    {
        var sqlStatement : String = "INSERT"
        if (!status.isEmpty ){
            sqlStatement += "  OR " + status
        }
        sqlStatement += " INTO " + tableName
        let columnStr = "(" +  columns.joined(separator: ", ") + ")"
        
        let values = " VALUES (:" + columns.joined(separator: ", :") + ")"
        
        sqlStatement += columnStr + values
     //   sqlStatement+" ON CONFLICT " + status
        return sqlStatement
    }
    
    /**
    */
    func buildInsertStatement (_ database: FMDatabase, tableName: String, data : Dictionary<String, Any>)->String{
        return ""
    }
    

    /**
    */
    func queryAll(_ database: FMDatabase, tableName:String)->FMResultSet!{
     return nil
    }
    
    /** Run a query on the table
        - parameter tableName: name of table
        - parameter columns: columns to return. optional. passing nil will get all columns
        - parameter whereClause:  use ? for subbed in parameters. optional
        - parameter whereArgs: subbed in parameters
        - parameter sortBy: order by clause. optional
        - return: result set
    */
    func query(_ database: FMDatabase, tableName: String , columns: [String]?, whereClause: String?, whereArgs:[AnyObject]?, sortBy: String?)->FMResultSet!{
        var query : String = "Select "
      
        if (columns==nil){
            query += "* "
        }else{
            let colStr = columns?.joined(separator: ", ")
            query += colStr!
        }
        query += " FROM " + tableName
        
        if (whereClause != nil){
            query += " WHERE "  + whereClause!
        }
        
        //205        appendClause(query, " GROUP BY ", groupBy);
        //206        appendClause(query, " HAVING ", having);
        if (sortBy != nil){
            query +=  " ORDER BY " + sortBy!
        }
        
        return database.executeQuery (query, withArgumentsIn: whereArgs)
    }
    
     /** not currently needed
    */
    func queryNumEntries(_ database: FMDatabase, tableName: String, whereClause: String!)->Int32{
        return 0;
    }
    
    /** formats the date in the yyy-MM-dd HH:mm:ss format
    parameter date : date to format
    returns: formatted string
    */
    open func formatDate(_ date: Date)->String{
        return dateFormater.string(from: date)
    }
    
    
    
    /** runs a query where each row is unique
    - parameter tableName: name of table
    - parameter columns: columns to return. optional. passing nil will get all columns
    - parameter whereClause:  use ? for subbed in parameters. optional
    - parameter limit: count as a string
    - return: result set
    */
    func queryDistinct(_ database: FMDatabase, table: String , columns: [String]?, whereClause: String?,  limit: String? )->FMResultSet!{
        var query : String = "Select "
        query += "DISTINCT "
        
        if (columns==nil){
            query += "* "
        }else{
            let colStr =  columns?.joined(separator: ", ")
            query += colStr!
        }
        query += " FROM "
        query += table
        
        if (whereClause != nil){
            query += " WHERE "  + whereClause!
        }
       
        //205        appendClause(query, " GROUP BY ", groupBy);
        //206        appendClause(query, " HAVING ", having);
        //207        appendClause(query, " ORDER BY ", orderBy);
        if (limit != nil){
            query += " LIMIT " + limit!
        }
        
        return database.executeQuery (query, withArgumentsIn: nil)
    }
}
