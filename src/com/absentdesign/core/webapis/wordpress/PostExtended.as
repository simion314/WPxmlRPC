package com.absentdesign.core.webapis.wordpress
{
	public class PostExtended extends Post
	{
		public var wp_post_thumbnail:int=215;
		//public var post_thumbnail:int=215;
		public function PostExtended(p:Post=null)
		{
			super();
			if(p){
				this.categories=p.categories;
				this.dateCreated=p.dateCreated;
				this.description=p.description;
				this.link=p.link;
				this.mt_allow_comments=p.mt_allow_comments;
				this.mt_allow_pings=p.mt_allow_pings;
				this.mt_keywords=p.mt_keywords;
				this.permaLink=p.permaLink;
				this.post_type=p.post_type;
				this.postid=p.postid;
				this.publish=p.publish;
				this.title=p.title;
				this.userid=p.userid;
				this.title=p.title;
				this.sticky=p.sticky;
				
			}
		}
	}
}