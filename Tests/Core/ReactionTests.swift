//
//  ReactionTests.swift
//  GetStream-iOS Tests
//
//  Created by Alexey Bukhtin on 27/12/2018.
//  Copyright © 2018 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import GetStream

class ReactionTests: TestCase {
    
    func testAdd() {
        client.add(reactionTo: .test1, kindOf: .comment, extraData: Comment(text: "Hello!"), userTypeOf: User.self) {
            let commentReaction = try! $0.get()
            XCTAssertEqual(commentReaction.kind, .comment)
            XCTAssertEqual(commentReaction.data.text, "Hello!")
            
            self.client.add(reactionTo: .test1, parentReactionId: commentReaction.parentId, kindOf: .like) {
                let likeReaction = try! $0.get()
                XCTAssertEqual(likeReaction.kind, .like)
                XCTAssertEqual(likeReaction.parentId, commentReaction.id)
            }
            
            self.client.add(reactionToParentReaction: commentReaction, kindOf: .like, userTypeOf: User.self) {
                let likeReaction = try! $0.get()
                XCTAssertEqual(likeReaction.kind, .like)
                XCTAssertEqual(likeReaction.parentId, commentReaction.id)
            }
        }
    }
    
    func testGet() {
        client.get(reactionId: .test1) {
            let reaction = try! $0.get()
            XCTAssertEqual(reaction.kind, .like)
            XCTAssertEqual(reaction.data, EmptyReactionExtraData.shared)
        }
        
        client.get(reactionId: .test2, extraDataTypeOf: Comment.self, userTypeOf: User.self) {
            let reaction = try! $0.get()
            XCTAssertEqual(reaction.kind, .comment)
            XCTAssertEqual(reaction.data.text, "Hello!")
        }
        
        client.get(reactionId: .test2) {
            let reaction = try! $0.get()
            XCTAssertEqual(reaction.kind, .comment)
            XCTAssertEqual(reaction.data, EmptyReactionExtraData.shared)
        }
    }
    
    func testUpdate() {
        client.update(reactionId: .test2, extraData: ReactionExtraData.comment("Hi!"), userTypeOf: User.self) {
            let reaction = try! $0.get()
            XCTAssertEqual(reaction.kind, .comment)
            
            
            if case .comment(let text) = reaction.data {
                XCTAssertEqual(text, "Hi!")
            }
            
            if let lastLike = reaction.latestChildren[.like]?.first {
                XCTAssertEqual(lastLike.kind, .like)
            }
            
            if let lastComment = reaction.latestChildren[.comment]?.first {
                XCTAssertEqual(lastComment.kind, .comment)
                
                if case .comment(let text) = lastComment.data {
                    XCTAssertEqual(text, "Hey!")
                }
            }
        }
    }
    
    func testDelete() {
        client.delete(reactionId: .test1) {
            XCTAssertEqual(try! $0.get(), 200)
        }
    }
    
    func testFetchReactions() {
        client.reactions(forUserId: "1") {
            let reactions = try! $0.get()
            XCTAssertEqual(reactions.reactions.count, 3)
        }
        
        client.reactions(forUserId: "1", kindOf: .comment, extraDataTypeOf: ReactionExtraData.self, userTypeOf: User.self) {
            let reactions = try! $0.get()
            XCTAssertEqual(reactions.reactions.count, 2)
            
            if case .comment(let text) = reactions.reactions[0].data {
                XCTAssertEqual(text, "Hey!")
            }
            
            if case .comment(let text) = reactions.reactions[1].data {
                XCTAssertEqual(text, "Hi!")
            }
        }
        
        client.reactions(forReactionId: "50539e71-d6bf-422d-ad21-c8717df0c325") {
            let reactions = try! $0.get()
            XCTAssertEqual(reactions.reactions.count, 2)
        }
        
        client.reactions(forActivityId: "ce918867-0520-11e9-a11e-0a286b200b2e", withActivityData: true) {
            let reactions = try! $0.get()
            XCTAssertEqual(reactions.reactions.count, 3)
            XCTAssertNotNil(try? reactions.activity(typeOf: Activity.self))
        }
    }
}
