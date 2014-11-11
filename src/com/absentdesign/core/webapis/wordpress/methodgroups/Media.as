package com.absentdesign.core.webapis.wordpress.methodgroups {
import com.absentdesign.core.webapis.wordpress.MediaItemFilter;
import com.absentdesign.core.webapis.wordpress.MediaObject;
import com.absentdesign.core.webapis.wordpress.WPService;
import com.absentdesign.core.webapis.wordpress.WPServiceRequest;
import com.absentdesign.core.webapis.wordpress.events.WPServiceEvent;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.filesystem.File;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import mx.utils.UIDUtil;

public class Media extends WPMethodGroup {
    public function Media(service:WPService) {
        super(service);
    }

    public function uploadImage(uri:String, post_id:int, onDone:Function):void {
        var _loader:URLLoader = new URLLoader();
        _loader.dataFormat = URLLoaderDataFormat.BINARY;
        _loader.addEventListener(Event.COMPLETE, dlComplete);
        _loader.addEventListener(IOErrorEvent.IO_ERROR, dlError);
        _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, dlError);
        var req:URLRequest = new URLRequest(uri);
        _loader.load(req);

        function dlComplete(e:Event):void {
            var ba:ByteArray = _loader.data;
            uploadFileAndAttachToPost(uri, ba, post_id, fUpd);
        }

        function unloadLoader():void {
            _loader.removeEventListener(Event.COMPLETE, dlComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, dlError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, dlError);
            _loader = null;
        }

        function fUpd(event:WPServiceEvent):void {
            var id:int = event.data.id;
            onDone(id)
        }

        function dlError(e:Event):void {
            onDone(-1);
        }
    }

    public function uploadFileAndAttachToPost(path:String, data:ByteArray, post_id:int, fUpd:Function):void {
        try {
            var f:File = new File(path);
            var fname:String = f.name;
            var fext:String = f.extension;
        } catch (er:Error) {
            var a:Array = path.split("/");
            if (a.length > 0) {
                fname = a.pop();
                if (fname == "") {
                    fname = UIDUtil.createUID().replace(/\-/g, "");
                    fext = "jpg";
                } else {
                    fext = fname.split(".").pop();
                    if (fext == "") {
                        fext = "jpg";
                    }
                }
            }
        }
        var type:String = "image/" + fext;
        service.addEventListener(WPServiceEvent.UPLOAD_FILE, fUpd);
        this.uploadFile(fname, type, data, true, post_id);
    }

    /**
     * Wrapper for wp.uploadFile - uploads the supplied file
     * <p>Will dispatch a ServiceEvent of type WPServiceEvent.UPLOAD_FILE with an array of blogs
     * as the WPServiceEvent.data once loaded</p>
     */
    public function uploadFile(name:String, type:String, data:ByteArray, overwrite:Boolean = true, post_id:int = 0):void {
        var content:MediaObject = new MediaObject();
        content.name = name;
        content.type = type;//the mimetype ex image/jpg
        content.bits = data;

        content.overwrite = overwrite;
        if (post_id > 0) {
            var moe:MediaObjectExtended = new MediaObjectExtended();
            moe.name = name;
            moe.type = type;//the mimetype ex image/jpg
            moe.bits = data;
            moe.overwrite = overwrite;
            content = moe;
        }

        var request:WPServiceRequest = new WPServiceRequest(
                service as WPService,
                "wp.uploadFile",
                [blogId, username, password, content],
                WPMethodGroupHelper.UPLOAD_FILE,
                WPServiceEvent.UPLOAD_FILE
        );
        loadRequest(request, uploadFile, name, type, data, overwrite);
    }

    public function getMediaItem(attachmentId:int):void {
        var request:WPServiceRequest = new WPServiceRequest(
                service as WPService,
                "wp.getMediaItem",
                [blogId, username, password, attachmentId],
                WPMethodGroupHelper.PARSE_MEDIA_ITEM,
                WPServiceEvent.GET_MEDIA_ITEM
        );
        loadRequest(request, getMediaItem, attachmentId);
    }

    public function getMediaLibrary(number:int = -1, offset:int = -1, parentId:int = -1, mimeType:String = "", useFilter:Boolean = false):void {
        var argsArray:Array;
        if (useFilter) {
            var filter:MediaItemFilter = new MediaItemFilter();
            filter.mime_type = mimeType;
            filter.number = number;
            filter.offset = offset;
            filter.parent_id = parentId;
            argsArray = [blogId, username, password, filter];
        } else {
            argsArray = [blogId, username, password];
        }
        var request:WPServiceRequest = new WPServiceRequest(
                service as WPService,
                "wp.getMediaLibrary",
                argsArray,
                WPMethodGroupHelper.PARSE_MEDIA_LIBRARY,
                WPServiceEvent.GET_MEDIA_LIBRARY
        );
        loadRequest(request, getMediaLibrary, number, offset, parentId, mimeType, useFilter);
    }

    /*
     wp.getMediaLibrary

     This call get a list of items in the user's Media Library with IDs, titles, descriptions, remote links, and any other relevant metadata. A filter parameter could be provided that would allow the caller to filter based on content type, file size, or other properties.
     Parameters

     int blog_id
     string username
     string password
     struct filter (optional)
     int number
     int offset
     int parent_id
     string mime_type (e.g., 'image/jpeg', 'application/pdf')

     Return Values

     array
     struct Same as wp.getMediaItem

     wp.getMediaItem

     This call would get a specific item in the user's Media Library by providing an ID. The call would return the item's ID, title, description, remote link, and any other available metadata.
     Parameters

     int blog_id
     string username
     string password
     int attachment_id

     Return Values

     struct
     date_created_gmt
     parent
     link
     thumbnail
     title
     caption
     description
     metadata
     */


}
}