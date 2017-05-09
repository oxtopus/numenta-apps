// Numenta Platform for Intelligent Computing (NuPIC)
// Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
// Numenta, Inc. a separate commercial license for this software code, the
// following terms and conditions apply:
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero Public License version 3 as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero Public License for more details.
//
// You should have received a copy of the GNU Affero Public License
// along with this program.  If not, see http://www.gnu.org/licenses.
//
// http://numenta.org/licenses/


/**
* Represent one tweet
*/
class Tweet  {
    var id: String!
    var created: Int64
    var aggregated: Int64
    var userId: String!
    var userName: String!
    var text: String!
    var hasLinks: Bool
    var cannonicalText: String!
  
    var aggregatedCount: Int32
    var retweetCount: Int32
    var retweetTotal: Int32
    
    
    //  // Match "RT @tags" from the beginning of the text.
    let RT_REGEX: String = "^\\s*RT\\s+(@[a-zA-Z][_a-zA-Z0-9]*\\s*)*"
    //  // From left side – Match @, #, $ up to colon symbol
    let LEFT_HASHTAG_UP_TO_COLON_REGEX: String! = "^\\s*([@#$][a-zA-Z][_a-zA-Z0-9]*\\s?)*:\\s*"
    //  // From left side – Match @, #, $ up to last
    let LEFT_HASHTAG_UP_TO_LAST_REGEX : String =  "^\\s*([@#$][a-zA-Z][_a-zA-Z0-9]*\\s*){2,}"
    //  // From right side – Match @, #, $ when followed by letter, not a number
    let RIGHT_HASHTAG_REGEX: String = "\\s*([@#$][a-zA-Z][_a-zA-Z0-9]*\\s*)+\\s*$"
    //  // Match "http" or "https" URLs
    let LINKS_REGEX: String = "\\s*https?:\\/\\/\\S+\\s*"
    //  // Match "..." at the end of the text
    let DOT_DOT_DOT_REGEX: String = "\\s*\\.{2,}\\s*$"
    //  // Match 2 or more spaces
    let TWO_OR_MORE_SPACES_REGEX: String = "\\s+"
    

    init(id: String!, aggregated: Int64, created: Int64, userId: String!, userName: String!, text: String!, retweetTotal: Int32) {
        self.userName = userName
        self.userId = userId
        self.created = created
        //  // Make sure aggregated values are rounded to closest 5 minute interval
        self.aggregated = DataUtils.floorTo5minutes(aggregated)
        self.id = id
        self.retweetTotal = retweetTotal
        
        self.text = text;
        self.cannonicalText = text
        self.hasLinks = false
        self.aggregatedCount = 0
        self.retweetCount = 0
        
        self.cannonicalText = self.makeCannonicalText(text)

        
              //  // Clean up HTML encoded text
       var cleanedText = text.replacingOccurrences(of: "&amp;", with: "&")
        cleanedText = cleanedText.replacingOccurrences(of: "&quot;", with: "\"")
        cleanedText = cleanedText.replacingOccurrences(of: "&lt;", with: "<")
        cleanedText = cleanedText.replacingOccurrences(of: "&gt;", with: ">")
 
        self.text = cleanedText
        
        
    }

    /**
    * Return twitter text without retweets (RT) and other decorators. The current logic is:
    *
    * <ul>
    * <li> Remove "RT " from the beginning of the text up to the colon.</li>
    * <li> Remove all links from the text.</li>
    * <li> From left side – remove @, #, $ up to colon symbol.</li>
    * <li> If no colon – remove @, #, $ when there are multiple in a row (up to last one).</li>
    * <li>From right side – remove @, #, $ (only remove $ when followed by letter, not a number)
    * up to text</li>
    * </ul>
    * <p>
    * For example:
    * <ol>
    * <li>
    * <b>Original:</b> "RT @Kelly_Evans: Salesforce $CRM just reopened over at Post 6 and surging
    * 13% on BBG reports of possible suitors @NYSE"
    * <br>
    * <b>Condensed:</b> "Salesforce $CRM just reopened over at Post 6 and surging 13% on BBG
    * reports of possible suitors"
    * </li>
    * <li>
    * <b>Original:</b> "RT @hblodget: Someone offered to buy Salesforce! RT@SAI: Salesforce
    * has hired advisors to fend off takeover offers $CRM http://t.co/DGfSez"
    * <br>
    * <b>Condensed: </b>"Someone offered to buy Salesforce! RT@SAI: Salesforce has hired
    * advisors to fend off takeover offers $CRM <b>link</b>"
    * </li>
    * <li>
    * <b>Original:</b> "RT @BloombergDeals: Breaking on Bloomberg: http://t.co/nuMtaw43j is
    * said to hire bankers to field takeover interest. Terminal link: http://t.co/ssfSEca3rk"
    * <br>
    * <b>Condensed:</b> "Breaking on Bloomberg: is said to hire bankers to field takeover
    * interest. Terminal link: <b>link</b>"
    * </li>
    * <li>
    * <b>Original:</b> "RT @OptionHawk: $CRM takeover talks, whoa!"
    * <br>
    * <b>Condensed:</b> "$CRM takeover talks, whoa!"
    * </li>
    * <li>
    * <b>Original:</b> "$SUTI Has now seen 400% gains in the past 2 weeks!
    * Special update: http://t.co/DGfSez3QA $ESRX $COST $BIIB"
    * <br>
    * <b>Condensed:</b> "Has now seen 400% gains in the past 2 weeks! Special update: <b>link</b>"
    * </li>
    * <li>
    * <b>Original:</b> "MCD McDonalds Corp. Volume http://t.co/sfda3SDA $MCD $DG $MRO $FCEL
    * $MCD #stock #tradeideas"
    * <br>
    * <b>Condensed:</b> "MCD McDonalds Corp. Volume <b>link</b>"
    * </li>
    * <li>
    * <b>Original:</b> "RT @wbznewsradio: NEW: @CharterCom to buy @TWC for $53.33 billion in
    * cash-and-stock deal. Charter will also buy @BrighHouseNow for $10B+"
    * <br>
    * <b>Condensed:</b> "NEW: @CharterCom to buy @TWC for $53.33 billion in cash-and-stock
    * deal. Charter will also buy @BrighHouseNow for $10B+"
    * </li>
    * </ol>
    * </p>
    */
    func makeCannonicalText( _ rawTweet : String)->String{
         var rawText: String = rawTweet
        
        
        // Remove ...
        
        let dotdotdotRegEx = try! NSRegularExpression(pattern: DOT_DOT_DOT_REGEX,
            options: [.caseInsensitive])
        rawText = dotdotdotRegEx.stringByReplacingMatches(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ), withTemplate: "")
        
        // Links
        let linkRegEx = try! NSRegularExpression(pattern: LINKS_REGEX,
            options: [.caseInsensitive])
        
       
        if ( linkRegEx.firstMatch(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ) ) != nil ){
                
                self.hasLinks = true
                
                rawText = linkRegEx.stringByReplacingMatches(in: rawText, options:[],
                    range: NSMakeRange(0, rawText.characters.count ), withTemplate: " ")
                
        }
        
        
        let rtRegEx = try! NSRegularExpression(pattern: RT_REGEX,
            options: [.caseInsensitive])
        rawText = rtRegEx.stringByReplacingMatches(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ), withTemplate: " ")
       
        let leftHashRegEx = try! NSRegularExpression(pattern: LEFT_HASHTAG_UP_TO_COLON_REGEX,
            options: [.caseInsensitive])
       

        
        if ( leftHashRegEx.firstMatch(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ) ) != nil ){
        
                rawText = leftHashRegEx.stringByReplacingMatches(in: rawText, options:[],
                    range: NSMakeRange(0, rawText.characters.count ), withTemplate: " ")
                
        }else{
            rawText = leftHashRegEx.stringByReplacingMatches(in: rawText, options:[],
                range: NSMakeRange(0, rawText.characters.count ), withTemplate: "$1")

        }
        
        // Remove hash tags from the right
        let rightHashRegEx = try! NSRegularExpression(pattern: RIGHT_HASHTAG_REGEX,
            options: [.caseInsensitive])
        rawText = rightHashRegEx.stringByReplacingMatches(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ), withTemplate: " ")
        
        
        let twospaceRegEx = try! NSRegularExpression(pattern: TWO_OR_MORE_SPACES_REGEX,
            options: [.caseInsensitive])
        rawText = twospaceRegEx.stringByReplacingMatches(in: rawText, options:[],
            range: NSMakeRange(0, rawText.characters.count ), withTemplate: " ")

        rawText =  rawText.replacingOccurrences(of: "\\n", with:"")
        rawText = rawText.replacingOccurrences(of: "\\r", with:"")
        
        
        
     // Remove duplicate tweets using specific set of rules. See "getCannonicalText"for rules
        
        
        
        
       return rawText
    
    }



}
