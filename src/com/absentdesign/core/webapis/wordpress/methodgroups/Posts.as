/**
 * Copyright (c) 2009, Reuben Stanton
 All rights reserved.
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
 following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
 disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
 following disclaimer in the documentation and/or other materials provided with the distribution.
 * The name "Reuben Stanton" may not be used to endorse or promote products derived from this software without 
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


package com.absentdesign.core.webapis.wordpress.methodgroups{
	
	import com.absentdesign.core.webapis.events.ServiceEvent;
	import com.absentdesign.core.webapis.wordpress.*;
	import com.absentdesign.core.webapis.wordpress.events.WPServiceEvent;
	import com.adobe.protocols.dict.events.ErrorEvent;
	import com.adobe.xml.syndication.generic.Image;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.events.FaultEvent;
	
	import org.osmf.logging.Logger;
	
	
	/**
	 * concrete WPMethodGroup for manipulating Posts 
	 */
	public class Posts extends WPMethodGroup{
		
		public function Posts(service:WPService){
			super(service);
		}
		
		/**
		 * Wrapper for metaWeblog.deletePost - deletes a single post
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.DELETE_POST with a struct 
		 * as the WPServiceEvent.data once loaded</p>
		 * 
		 * @param postId The id of the post to delete
		 */
		public function deletePost(postId:int):void{			
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.deletePost",
				[0,postId,username,password,true],
				WPMethodGroupHelper.DELETE_POST,
				WPServiceEvent.DELETE_POST
			);
			
			loadRequest(request,deletePost,postId);
		}
		
		/**
		 * Wrapper for metaWeblog.getPost - gets a single post
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.GET_POST with a Post 
		 * as the WPServiceEvent.data once loaded</p>
		 * 
		 * @param postId The id of the post to retreive
		 */
		public function getPost(postId:int):void{			
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.getPost",
				[postId,username,password],
				WPMethodGroupHelper.PARSE_POST,
				WPServiceEvent.GET_POST
			);
			loadRequest(request,getPost,postId);
		}
		
		/**
		 * Wrapper for metaWeblog.newPost - add a new Post
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.NEW_POST once loaded</p>
		 * 
		 * @param content the new Post
		 * @param publish whether to publish immediately or save as a draft
		 */
		public function newPost(content:Post,publish:Boolean,onDone:Function=null,featuredImageUri:String=null):void{			
			if(featuredImageUri)
			{
				this.newPostWithFeaturedImage(content,publish,onDone,featuredImageUri);
				return;
			}
			else
			{
				var service : WPService=service as  WPService;
				if(onDone!=null)
				{//fix this by creating an anonymus fuynction that will call onDone
					service.addEventListener(WPServiceEvent.NEW_POST,onDone);
					service.addEventListener(FaultEvent.FAULT,onDone);
				}
			}
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.newPost",
				[blogId,username,password,content,publish],
				WPMethodGroupHelper.NEW_POST,
				WPServiceEvent.NEW_POST
			);
			//loadRequest(request,newPost,content,publish);
			loadRequestMoreoptions(request,processAndDispatch,dispatchFault);
		}
		private function connectToService(onDone:Function):void{
			var service:WPService = this.service as WPService;
			if(service.connected){
				onDone();
				return;
			}
			service.addEventListener(WPServiceEvent.CONNECTED,onServiceConnected,false,0,true);
			if(!service.connecting){
				service.connect();
			}
			function onServiceConnected(e:Event):void{
				onDone();
			}
		}
		public function loadRequestMoreoptions(request:WPServiceRequest,onCompletHandler:Function,onFault:Function):void{
			var service:WPService = this.service as WPService;
			if(service.connected){
				request.showBusyCursor=this.showBusyCursor;
				request.addEventListener(ServiceEvent.COMPLETE,onCompletHandler,false,0,true);
				request.addEventListener(FaultEvent.FAULT,onFault,false,0,true); 
			
				request.load();
			}
			else {
				connectToService(function():void{loadRequestMoreoptions(request,onCompletHandler,onFault)});
			}
		}
		
		private function newPostWithNoEventsDispatched(content:Post,onPosted:Function,onFault:Function):void{
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.newPost",
				[blogId,username,password,content,false],
				WPMethodGroupHelper.NEW_POST,
				WPServiceEvent.NEW_POST
			);
			//loadRequest(request,newPost,content,publish);
			loadRequestMoreoptions(request,onPosted,onFault);
		}
		
		public function newPostWithFeaturedImage(content:Post, publish:Boolean,onDone:Function,featuredImageUri:String):void
		{
			//TODO314
			var uri:String=featuredImageUri;
			//first do a post but do not publish it
			var post_id:int;
			newPostWithNoEventsDispatched(content,onPosted,onFault);
			
			function onPosted(event:Event):void{
				if(event is ErrorEvent){
					trace("Posts.onPosted "+event.toString());
					onFault("Error posting!");
					return;
				}
				var request:WPServiceRequest = event.target as WPServiceRequest;
				request.removeEventListener(ServiceEvent.COMPLETE,processAndDispatch);
				var p:Object=helper.parse(request.data, request.parseFunction);
				post_id=parseInt(p as String);
				if(post_id<=0){
					trace("invalid post id");
					onFault("Error posting!");
					return;
				}
				if(uri.indexOf("http")!=0)
					uploadImage(uri,post_id,afterUpload);
				else
					downloadImage(uri,afterDownload);
				
				function afterDownload(ba:ByteArray):void{
					uploadImageBytes(uri,ba,post_id,afterUpload);
				}
				function afterUpload(attachmentId:int):void{
					setFeatureImgandPublishPost(post_id,attachmentId,content,publish,onDone);
				}
			}	
			function onFault(f:Object):void{
				trace(f);
				onDone(f);
			}
		}
		private function setFeatureImgandPublishPost(post_id:int, attachmentId:int,content:Post,publish:Boolean,onDone:Function):void
		{
			var cextended:PostExtended=new PostExtended(content);
			cextended.wp_post_thumbnail=attachmentId;
			editPost(post_id,cextended,publish,onEdited,null);
			function onEdited(e:Object):void{
				if(e.hasOwnProperty("data")&& e.data==true){
					e.data=post_id;
				}
				onDone(e);
			}
		}
		private function uploadImage(path:String, post_id:int, afterUpload:Function):void
		{
			connectToService(onDone);
			function onDone():void{
				var wps:WPService = service as WPService;
				wps.media.uploadImage(path,post_id,afterUpload);
			}
		}
		private function uploadImageBytes(path:String,ba:ByteArray, post_id:int, afterUpload:Function):void
		{
			connectToService(onDone);
			function onDone():void{
				var wps:WPService = service as WPService;
				wps.media.uploadFileAndAttachToPost(path,ba,post_id,onUploaded);
			}
			function onUploaded(event:WPServiceEvent):void{
				var id:int=event.data.id;
				afterUpload(id)
			}
		}
		private function downloadImage(uri:String,onDone:Function):void{
			var req:URLRequest=new URLRequest(uri);
			var _loader:URLLoader=new URLLoader();
			_loader.dataFormat=URLLoaderDataFormat.BINARY;
			_loader.addEventListener(Event.COMPLETE, dlComplete);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, dlError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, dlError);
			_loader.load(req); 
			function dlError(e:ErrorEvent):void {
				_loader.removeEventListener(Event.COMPLETE, dlComplete);
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, dlError);
				_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, dlError);
				onDone(null);
			}
			function dlComplete(e:Event):void {
				_loader.removeEventListener(Event.COMPLETE, dlComplete);
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, dlError);
				_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, dlError);
				var ba:ByteArray=_loader.data;
				onDone(ba);
			}
		}
		
		
		/**
		 * Wrapper for metaWeblog.getRecentPosts - gets an array of recent posts
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.GET_RECENT_POSTS with an Array 
		 * of posts as the WPServiceEvent.data once loaded</p>
		 * 
		 * @param count The number of posts to retreive. If you want all posts just use a really high number (999999)
		 */
		public function getRecentPosts(count:uint = 10):void{			
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.getRecentPosts",
				[blogId,username,password,count],
				WPMethodGroupHelper.PARSE_RECENT_POSTS,
				WPServiceEvent.GET_RECENT_POSTS
			);
			loadRequest(request,getRecentPosts,count);
		}
		
		private function handleEditWithFeaturedImage(postId:int,content:Post,publish:Boolean,callback:Function,featuredImageUri:String):void{
			//first upload image to WP
			var uri:String=featuredImageUri;
			
			if(postId<=0){
				trace("invalid post id");
				onFault("Error posting!");
				return;
			}
			if(uri.indexOf("http")!=0)
				uploadImage(uri,postId,afterUpload);
			else
				downloadImage(uri,afterDownload);
			function afterDownload(ba:ByteArray):void{
				uploadImageBytes(uri,ba,postId,afterUpload);
			}
			function afterUpload(attachmentId:int):void{
				setFeatureImgandPublishPost(postId,attachmentId,content,publish,callback);
			}
			function onFault(f:Object):void{
				trace(f);
				callback(f);
			}
		}
		/**
		 * Wrapper for metaWeblog.editPost - edit a specific post
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.EDIT_POST with a struct
		 * as the WPServiceEvent.data once loaded</p>
		 * 
		 * @param postId the id of the post to edit
		 * @param content the new post data
		 * @param publish whether to publish immediately or save as a draft 
		 */
		public function editPost(postId:int,post:Post,publish:Boolean,callback:Function,featuredImageUri:String):void{			
			if(featuredImageUri)
			{
				this.handleEditWithFeaturedImage(postId,post,publish,callback,featuredImageUri);
				return;
			}
			if(callback!=null)
			{
				var wps:WPService=service as WPService;
				wps.addEventListener(WPServiceEvent.EDIT_POST, postEdited);
				wps.addEventListener(FaultEvent.FAULT,postEdited);
			}
			function postEdited(e:Event):void{
				callback(e);
			}
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"metaWeblog.editPost",
				[postId,username,password,post,publish],
				WPMethodGroupHelper.EDIT_POST,
				WPServiceEvent.EDIT_POST
			);
			loadRequest(request,editPost,postId,post,publish,null);
		}
		
		/**
		 * Wrapper for mt.getRecentPostTitles - gets a bandwidth friendly an array of recent posts
		 * <p>Will dispatch a ServiceEvent of type WPServiceEvent.GET_RECENT_POST_TITLES with an Array 
		 * of Posts as the WPServiceEvent.data once loaded</p>
		 * 
		 * @param numberOfPosts The number of posts to retreive. If you want all weblog posts just use a really high number (999999)
		 */
		public function getRecentPostTitles(numberOfPosts:uint = 10):void{			
			var request:WPServiceRequest = new WPServiceRequest(
				service as WPService,
				"mt.getRecentPostTitles",
				[blogId,username,password,numberOfPosts],
				WPMethodGroupHelper.PARSE_RECENT_POST_TITLES,
				WPServiceEvent.GET_RECENT_POST_TITLES
			);
			loadRequest(request,getRecentPostTitles,numberOfPosts);
		}
		
		
	}
	
	
}

