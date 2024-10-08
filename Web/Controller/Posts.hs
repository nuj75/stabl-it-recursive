{-# OPTIONS_GHC -Wno-incomplete-patterns #-}
module Web.Controller.Posts where

import Web.Controller.Prelude
import Web.View.Posts.Index
import Web.View.Posts.New
import Web.View.Posts.Edit
import Web.View.Posts.Show
import Text.XML.Cursor (parent)
import Data.UUID


instance Controller PostsController where
    action PostsAction = do
        posts <- query @Post 
            |> filterWhereSql (#parentId, "IS NULL")
            |> fetch 

        render IndexView { .. }

    action NewPostAction { parentId } = do
        let post = 
                case parentId of
                    Just x -> ((case (fromText x) of
                                    Just y -> newRecord
                                                |> set #parentId (Just y)
                                    Nothing ->  newRecord
                                ))
                    Nothing -> newRecord
                
        render NewView { .. }

    action ShowPostAction { postId } = do
        post <- fetch postId
        comments <- query @Post 
            |> filterWhere (#parentId, Data.UUID.fromText (postId |> show))
            |> fetch 
        render ShowView { .. }

    action EditPostAction { postId } = do
        post <- fetch postId
        render EditView { .. }

    action UpdatePostAction { postId } = do
        post <- fetch postId
        post
            |> buildPost
            |> ifValid \case
                Left post -> render EditView { .. }
                Right post -> do
                    post <- post |> updateRecord
                    setSuccessMessage "Post updated"
                    redirectTo EditPostAction { .. }

    action CreatePostAction = do
        let post = newRecord @Post
                    
        post
            |> buildPost
            |> ifValid \case
                Left post -> redirectTo PostsAction
                Right post -> do
                    post <- post |> createRecord
                    setSuccessMessage "Post created"
                    case post.parentId of
                        Just x -> redirectTo ShowPostAction { postId = Id x }
                        Nothing -> redirectTo PostsAction

    action DeletePostAction { postId } = do
        post <- fetch postId
        deleteRecord post
        setSuccessMessage "Post deleted"
        redirectTo PostsAction


    action LikePost { postId } = do

        updatePost <- fetch ( postId )
        updatePost
            |> set #likes (updatePost.likes + 1)
            |> updateRecord

        redirectTo ShowPostAction { ..}   


    action DislikePost { postId } = do
        updatePost <- fetch ( postId )
        updatePost
            |> set #likes (case updatePost.likes > 0 of
                                True -> updatePost.likes - 1
                                False -> updatePost.likes
                            )
            |> updateRecord

        

        redirectTo ShowPostAction { ..}        


buildPost post = post
    |> fill @'["title", "author", "likes", "parentId", "body"]
