//
//  HNPost.swift
//  HackerNews2
//
//  Created by Stéphane Sercu on 8/09/17.
//  Copyright © 2017 Stéphane Sercu. All rights reserved.
//

import Foundation

/// Model used by the HN Scraper to store avery data about a post.
open class HNPost: Identifiable, Hashable {
    public static func == (lhs: HNPost, rhs: HNPost) -> Bool {
        (lhs.id == rhs.id)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public enum PostType {
        case defaultType
        case askHN
        case jobs

        public init?(index: Int) {
            switch index {
            case 0: self = .defaultType
            case 1: self = .askHN
            case 2: self = .jobs
            default: return nil
            }
        }
    }

    public var type: PostType = .defaultType
    public var username: String = ""
    public var isOPNoob: Bool = false
    public var url: URL? // = URL(string: "")!
    public var urlDomain: String {
        if url == nil {
            return ""
        }
        var dom: String? = url!.host
        if dom != nil, dom!.hasPrefix("www.") {
            dom = String(dom!.dropFirst(4))
        }
        return dom ?? ""
    }

    public var title: String = ""
    public var points: Int = 0
    public var commentCount: Int = 0
    public var id: String = ""
    public var time: String = ""

    public var upvoted: Bool = false
    public var upvoteAdditionURL: String?

    public var favorited: Bool = false // TODO: there's no way to know from a "list page", but it could be filled from the discussion thread.

    public var replyAction: String?
    public var replyParent: String?
    public var replyGoto: String?
    public var replyHmac: String?
    public var replyText: String?

    public init() {}

    /**
     * Build the model by parsing the html of a post item on the HN website.
     * - parameters:
     *      - html: the html code to parse
     *      - parseConfig: the parameters from the json file containing all the needed parsing informations.
     */
    public convenience init?(fromHtml html: String, withParsingConfig parseConfig: [String: Any]) {
        self.init()

        let postsConfig: [String: Any]? = (parseConfig["Post"] != nil) ? parseConfig["Post"] as? [String: Any] : nil
        if postsConfig == nil {
            return nil
        }

        if html.contains("<td class=\"title\"> [dead] <a") {
            return nil
        }

        // Set Up for Scanning
        var postDict: [String: Any] = [:]
        let scanner = Scanner(string: html)
        var upvoteString: NSString? = ""

        // Scan for Upvotes
        if html.contains((postsConfig!["Vote"] as! [String: String])["R"]!) {
            scanner.scanBetweenString(stringA: (postsConfig!["Vote"] as! [String: String])["S"]!, stringB: (postsConfig!["Vote"] as! [String: String])["E"]!, into: &upvoteString)
            upvoteAdditionURL = upvoteString! as String
        }

        // Scan from JSON Configuration
        let parts = postsConfig!["Parts"] as! [[String: Any]]
        for part in parts {
            var new: NSString? = ""
            let isTrash = part["I"] as! String == "TRASH"

            scanner.scanBetweenString(stringA: part["S"] as! String, stringB: part["E"] as! String, into: &new)
            if !isTrash, (new?.length)! > 0 {
                postDict[part["I"] as! String] = new
            }
        }

        // Set Values
        url = postDict["UrlString"] != nil ? URL(string: postDict["UrlString"] as! String) : nil
        title = postDict["Title"] as? String ?? ""
        points = Int((postDict["Points"] as? String ?? "").components(separatedBy: " ")[0]) ?? 0
        username = postDict["Username"] as? String ?? ""
        isOPNoob = HNUser.cleanNoobUsername(username: &username)
        id = postDict["PostId"] as? String ?? ""
        time = postDict["Time"] as? String ?? ""
        if id != "", html.contains("<a id='un_\(id)") || html.contains("<a id='up_\(id)") && html.contains("class='nosee'><div class='votearrow'") {
            upvoted = true
        }

        if postDict["Comments"] != nil, postDict["Comments"] as! String == "discuss" {
            commentCount = 0
        } else if postDict["Comments"] != nil {
            let cScan = Scanner(string: postDict["Comments"] as! String)
            var cCount: NSString? = ""
            cScan.scanUpTo(" ", into: &cCount)
            commentCount = Int((cCount?.intValue)!)
        }

        // Check if Jobs Post
        if id.count == 0, points == 0, username.count == 0 {
            type = .jobs
            if url != nil, !url!.absoluteString.contains("http") {
                id = url!.absoluteString.replacingOccurrences(of: "item?id=", with: "")
                url = URL(string: "https://news.ycombinator.com/" + url!.absoluteString)!
            }
        } else {
            // Check if AskHN
            if url != nil, !url!.absoluteString.contains("http"), id.count > 0 {
                type = .askHN
                url = URL(string: "https://news.ycombinator.com/" + url!.absoluteString)!
            } else {
                type = .defaultType
            }
        }
    }
}
