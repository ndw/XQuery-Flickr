xquery version "1.0-ml";

module namespace flickr="http://www.flickr.com/services/api/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $key    := "YOUR API KEY";
declare variable $secret := "YOUR API SECRET";
declare variable $token  := "YOUR AUTH_TOKEN";

declare function flickr:_flickr(
    $method as element(flickr:method))
{
  flickr:_flickr-pages($method, ())
};

declare function flickr:_flickr-pages(
    $method as element(flickr:method),
    $result as element()?)
{
  let $args := for $arg in ($method/flickr:arg,
                            <flickr:arg name="api_key">{$key}</flickr:arg>,
                            if ($method/@auth="true")
                            then
                              <flickr:arg name="auth_token">{$token}</flickr:arg>
                            else
                              (),
                            <flickr:arg name="method">{string($method/@name)}</flickr:arg>)
               order by $arg/@name ascending
               return $arg
  let $sign := string-join(($secret, for $arg in $args return concat($arg/@name,$arg)), "")
  let $md5  := xdmp:md5($sign)
  let $uri  := concat("http://api.flickr.com/services/rest/?method=", $method/@name,
                      "&amp;api_key=", $key, "&amp;",
                      string-join(for $arg in $method/flickr:arg
                                  return concat($arg/@name, "=", string($arg)), "&amp;"),
                      if ($method/@auth="true")
                      then concat("&amp;auth_token=", $token)
                      else "",
                      "&amp;api_sig=", $md5)
  let $rsp  := xdmp:http-get($uri)
  return
    if ($rsp[2]/*/@stat = "ok")
    then
      let $body  := $rsp[2]/*/*
      let $page  := if ($body/@page and $body/@page castable as xs:integer)
                    then xs:integer($body/@page)
                    else 0
      let $pages := if ($body/@pages and $body/@pages castable as xs:integer)
                    then xs:integer($body/@pages)
                    else 0
      let $new   := if (empty($result))
                    then $body
                    else element { node-name($result) } { $body/@*, $result/*, $body/* }
      return
        if ($page < $pages and (not($method/flickr:arg[@name="page"]) or not(empty($result))))
        then
          let $newmethod := element { node-name($method) }
                                    { $method/@*, $method/*[not(@name='page')],
                                      <flickr:arg name="page">{$page + 1 }</flickr:arg>
                                    }
          return
            flickr:_flickr-pages($newmethod, $new)
        else
          flickr:_fixns($new)
    else
      <flickr:error>{$rsp}</flickr:error>
};

declare function flickr:_fixns($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
      case element()
        return
          if (namespace-uri($x) = "")
          then
            element { QName("http://www.flickr.com/services/api/", local-name($x)) }
                    { $x/@*, flickr:_fixns($x/node()) }
          else
            element { node-name($x) }
                    { $x/@*, flickr:_fixns($x/node()) }
      default
        return $x
};

(: ====================================================================== :)

declare function flickr:activity.userComments(
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.activity.userComments">
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:activity.userPhotos(
    $timeframe as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.activity.userPhotos">
                   { if (empty($timeframe))
                     then ()
                       else <arg name="timeframe">{$timeframe}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:auth.checkToken(
    $auth_token as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         sig="true"
                         name="flickr.auth.checkToken">
                   <arg name="auth_token">{$auth_token}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:auth.getFrob()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.auth.getFrob">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:auth.getFullToken(
    $mini_token as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         sig="true"
                         name="flickr.auth.getFullToken">
                   <arg name="mini_token">{$mini_token}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:auth.getToken(
    $frob as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         sig="true"
                         name="flickr.auth.getToken">
                   <arg name="frob">{$frob}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:blogs.getList()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.blogs.getList">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:blogs.postPhoto(
    $blog_id as xs:string,
    $photo_id as xs:string,
    $title as xs:string,
    $description as xs:string,
    $blog_password as xs:string?,
    $service as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.blogs.postPhoto">
                   <arg name="blog_id">{$blog_id}</arg>
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="title">{$title}</arg>
                   <arg name="description">{$description}</arg>
                   { if (empty($blog_password))
                     then ()
                       else <arg name="blog_password">{$blog_password}</arg> }
                   { if (empty($service))
                     then ()
                       else <arg name="service">{$service}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:contacts.getList(
    $filter as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.contacts.getList">
                   { if (empty($filter))
                     then ()
                       else <arg name="filter">{$filter}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:contacts.getPublicList(
    $user_id as xs:string,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.contacts.getPublicList">
                   <arg name="user_id">{$user_id}</arg>
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:favorites.add(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.favorites.add">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:favorites.getList(
    $user_id as xs:string?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.favorites.getList">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:favorites.getPublicList(
    $user_id as xs:string,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.favorites.getPublicList">
                   <arg name="user_id">{$user_id}</arg>
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:favorites.remove(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.favorites.remove">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.browse(
    $cat_id as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.groups.browse">
                   { if (empty($cat_id))
                     then ()
                       else <arg name="cat_id">{$cat_id}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.getInfo(
    $group_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.groups.getInfo">
                   <arg name="group_id">{$group_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.search(
    $text as xs:string,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.groups.search">
                   <arg name="text">{$text}</arg>
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.pools.add(
    $photo_id as xs:string,
    $group_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.groups.pools.add">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="group_id">{$group_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.pools.getContext(
    $photo_id as xs:string,
    $group_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.groups.pools.getContext">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="group_id">{$group_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.pools.getGroups(
    $page as xs:string?,
    $per_page as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.groups.pools.getGroups">
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.pools.getPhotos(
    $group_id as xs:string,
    $tags as xs:string?,
    $user_id as xs:string?,
    $extras as xs:string?,
    $page as xs:string?,
    $per_page as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.groups.pools.getPhotos">
                   <arg name="group_id">{$group_id}</arg>
                   { if (empty($tags))
                     then ()
                       else <arg name="tags">{$tags}</arg> }
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:groups.pools.remove(
    $photo_id as xs:string,
    $group_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.groups.pools.remove">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="group_id">{$group_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:interestingness.getList(
    $date as xs:date?,
    $extras as xs:string?,
    $page as xs:string?,
    $per_page as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.interestingness.getList">
                   { if (empty($date))
                     then ()
                       else <arg name="date">{$date}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.findByEmail(
    $find_email as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.findByEmail">
                   <arg name="find_email">{$find_email}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.findByUsername(
    $username as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.findByUsername">
                   <arg name="username">{$username}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.getInfo(
    $user_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.getInfo">
                   <arg name="user_id">{$user_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.getPublicGroups(
    $user_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.getPublicGroups">
                   <arg name="user_id">{$user_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.getPublicPhotos(
    $user_id as xs:string,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.getPublicPhotos">
                   <arg name="user_id">{$user_id}</arg>
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:people.getUploadStatus(
    $username as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.people.getUploadStatus">
                   <arg name="username">{$username}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.addTags(
    $photo_id as xs:string,
    $tags as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.addTags">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="tags">{$tags}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.delete(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.delete">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getAllContexts(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getAllContexts">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getContactsPhotos(
    $count as xs:integer?,
    $just_friends as xs:integer?,
    $single_photo as xs:string?,
    $include_self as xs:integer?,
    $extras as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getContactsPhotos">
                   { if (empty($count))
                     then ()
                       else <arg name="count">{$count}</arg> }
                   { if (empty($just_friends))
                     then ()
                       else <arg name="just_friends">{$just_friends}</arg> }
                   { if (empty($single_photo))
                     then ()
                       else <arg name="single_photo">{$single_photo}</arg> }
                   { if (empty($include_self))
                     then ()
                       else <arg name="include_self">{$include_self}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getContactsPublicPhotos(
    $user_id as xs:string,
    $count as xs:integer?,
    $just_friends as xs:integer?,
    $single_photo as xs:string?,
    $include_self as xs:integer?,
    $extras as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getContactsPublicPhotos">
                   <arg name="user_id">{$user_id}</arg>
                   { if (empty($count))
                     then ()
                       else <arg name="count">{$count}</arg> }
                   { if (empty($just_friends))
                     then ()
                       else <arg name="just_friends">{$just_friends}</arg> }
                   { if (empty($single_photo))
                     then ()
                       else <arg name="single_photo">{$single_photo}</arg> }
                   { if (empty($include_self))
                     then ()
                       else <arg name="include_self">{$include_self}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getContext(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getContext">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getCounts(
    $dates as xs:string?,
    $taken_dates as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getCounts">
                   { if (empty($dates))
                     then ()
                       else <arg name="dates">{$dates}</arg> }
                   { if (empty($taken_dates))
                     then ()
                       else <arg name="taken_dates">{$taken_dates}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getExif(
    $photo_id as xs:string,
    $secret as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getExif">
                   <arg name="photo_id">{$photo_id}</arg>
                   { if (empty($secret))
                     then ()
                       else <arg name="secret">{$secret}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getFavorites(
    $photo_id as xs:string,
    $page as xs:string?,
    $per_page as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getFavorites">
                   <arg name="photo_id">{$photo_id}</arg>
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getInfo(
    $photo_id as xs:string,
    $secret as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getInfo">
                   <arg name="photo_id">{$photo_id}</arg>
                   { if (empty($secret))
                     then ()
                       else <arg name="secret">{$secret}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getNotInSet(
    $min_upload_date as xs:string?,
    $max_upload_date as xs:string?,
    $min_taken_date as xs:string?,
    $max_taken_date as xs:string?,
    $privacy_filter as xs:integer?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getNotInSet">
                   { if (empty($min_upload_date))
                     then ()
                       else <arg name="min_upload_date">{$min_upload_date}</arg> }
                   { if (empty($max_upload_date))
                     then ()
                       else <arg name="max_upload_date">{$max_upload_date}</arg> }
                   { if (empty($min_taken_date))
                     then ()
                       else <arg name="min_taken_date">{$min_taken_date}</arg> }
                   { if (empty($max_taken_date))
                     then ()
                       else <arg name="max_taken_date">{$max_taken_date}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getPerms(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getPerms">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getRecent(
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getRecent">
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getSizes(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.getSizes">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getUntagged(
    $min_upload_date as xs:string?,
    $max_upload_date as xs:string?,
    $min_taken_date as xs:string?,
    $max_taken_date as xs:string?,
    $privacy_filter as xs:integer?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getUntagged">
                   { if (empty($min_upload_date))
                     then ()
                       else <arg name="min_upload_date">{$min_upload_date}</arg> }
                   { if (empty($max_upload_date))
                     then ()
                       else <arg name="max_upload_date">{$max_upload_date}</arg> }
                   { if (empty($min_taken_date))
                     then ()
                       else <arg name="min_taken_date">{$min_taken_date}</arg> }
                   { if (empty($max_taken_date))
                     then ()
                       else <arg name="max_taken_date">{$max_taken_date}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getWithGeoData(
    $min_upload_date as xs:string?,
    $max_upload_date as xs:string?,
    $min_taken_date as xs:string?,
    $max_taken_date as xs:string?,
    $sort as xs:string?,
    $privacy_filter as xs:integer?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getWithGeoData">
                   { if (empty($min_upload_date))
                     then ()
                       else <arg name="min_upload_date">{$min_upload_date}</arg> }
                   { if (empty($max_upload_date))
                     then ()
                       else <arg name="max_upload_date">{$max_upload_date}</arg> }
                   { if (empty($min_taken_date))
                     then ()
                       else <arg name="min_taken_date">{$min_taken_date}</arg> }
                   { if (empty($max_taken_date))
                     then ()
                       else <arg name="max_taken_date">{$max_taken_date}</arg> }
                   { if (empty($sort))
                     then ()
                       else <arg name="sort">{$sort}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.getWithoutGeoData(
    $min_upload_date as xs:string?,
    $max_upload_date as xs:string?,
    $min_taken_date as xs:string?,
    $max_taken_date as xs:string?,
    $sort as xs:string?,
    $privacy_filter as xs:integer?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.getWithoutGeoData">
                   { if (empty($min_upload_date))
                     then ()
                       else <arg name="min_upload_date">{$min_upload_date}</arg> }
                   { if (empty($max_upload_date))
                     then ()
                       else <arg name="max_upload_date">{$max_upload_date}</arg> }
                   { if (empty($min_taken_date))
                     then ()
                       else <arg name="min_taken_date">{$min_taken_date}</arg> }
                   { if (empty($max_taken_date))
                     then ()
                       else <arg name="max_taken_date">{$max_taken_date}</arg> }
                   { if (empty($sort))
                     then ()
                       else <arg name="sort">{$sort}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.recentlyUpdated(
    $min_date as xs:string,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.recentlyUpdated">
                   <arg name="min_date">{$min_date}</arg>
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.removeTag(
    $tag_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.removeTag">
                   <arg name="tag_id">{$tag_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.search(
    $user_id as xs:string?,
    $tags as xs:string?,
    $tag_mode as xs:string?,
    $text as xs:string?,
    $min_upload_date as xs:string?,
    $max_upload_date as xs:string?,
    $min_taken_date as xs:string?,
    $max_taken_date as xs:string?,
    $license as xs:string?,
    $sort as xs:string?,
    $privacy_filter as xs:integer?,
    $bbox as xs:string?,
    $accuracy as xs:integer?,
    $machine_tags as xs:string?,
    $machine_tag_mode as xs:string?,
    $group_id as xs:string?,
    $extras as xs:string?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.search">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                   { if (empty($tags))
                     then ()
                       else <arg name="tags">{$tags}</arg> }
                   { if (empty($tag_mode))
                     then ()
                       else <arg name="tag_mode">{$tag_mode}</arg> }
                   { if (empty($text))
                     then ()
                       else <arg name="text">{$text}</arg> }
                   { if (empty($min_upload_date))
                     then ()
                       else <arg name="min_upload_date">{$min_upload_date}</arg> }
                   { if (empty($max_upload_date))
                     then ()
                       else <arg name="max_upload_date">{$max_upload_date}</arg> }
                   { if (empty($min_taken_date))
                     then ()
                       else <arg name="min_taken_date">{$min_taken_date}</arg> }
                   { if (empty($max_taken_date))
                     then ()
                       else <arg name="max_taken_date">{$max_taken_date}</arg> }
                   { if (empty($license))
                     then ()
                       else <arg name="license">{$license}</arg> }
                   { if (empty($sort))
                     then ()
                       else <arg name="sort">{$sort}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($bbox))
                     then ()
                       else <arg name="bbox">{$bbox}</arg> }
                   { if (empty($accuracy))
                     then ()
                       else <arg name="accuracy">{$accuracy}</arg> }
                   { if (empty($machine_tags))
                     then ()
                       else <arg name="machine_tags">{$machine_tags}</arg> }
                   { if (empty($machine_tag_mode))
                     then ()
                       else <arg name="machine_tag_mode">{$machine_tag_mode}</arg> }
                   { if (empty($group_id))
                     then ()
                       else <arg name="group_id">{$group_id}</arg> }
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.setDates(
    $photo_id as xs:string,
    $date_posted as xs:string?,
    $date_taken as xs:string?,
    $date_taken_granularity as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.setDates">
                   <arg name="photo_id">{$photo_id}</arg>
                   { if (empty($date_posted))
                     then ()
                       else <arg name="date_posted">{$date_posted}</arg> }
                   { if (empty($date_taken))
                     then ()
                       else <arg name="date_taken">{$date_taken}</arg> }
                   { if (empty($date_taken_granularity))
                     then ()
                       else <arg name="date_taken_granularity">{$date_taken_granularity}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.setMeta(
    $photo_id as xs:string,
    $title as xs:string,
    $description as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.setMeta">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="title">{$title}</arg>
                   <arg name="description">{$description}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.setPerms(
    $photo_id as xs:string,
    $is_public as xs:integer,
    $is_friend as xs:integer,
    $is_family as xs:integer,
    $perm_comment as xs:integer,
    $perm_addmeta as xs:integer)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.setPerms">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="is_public">{$is_public}</arg>
                   <arg name="is_friend">{$is_friend}</arg>
                   <arg name="is_family">{$is_family}</arg>
                   <arg name="perm_comment">{$perm_comment}</arg>
                   <arg name="perm_addmeta">{$perm_addmeta}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.setTags(
    $photo_id as xs:string,
    $tags as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.setTags">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="tags">{$tags}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.comments.addComment(
    $photo_id as xs:string,
    $comment_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.comments.addComment">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="comment_text">{$comment_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.comments.deleteComment(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.comments.deleteComment">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.comments.editComment(
    $comment_id as xs:string,
    $comment_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.comments.editComment">
                   <arg name="comment_id">{$comment_id}</arg>
                   <arg name="comment_text">{$comment_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.comments.getList(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.comments.getList">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.geo.getLocation(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.geo.getLocation">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.geo.getPerms(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.geo.getPerms">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.geo.removeLocation(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.geo.removeLocation">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.geo.setLocation(
    $lat as xs:string,
    $lon as xs:string,
    $accuracy as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.geo.setLocation">
                   <arg name="lat">{$lat}</arg>
                   <arg name="lon">{$lon}</arg>
                   { if (empty($accuracy))
                     then ()
                       else <arg name="accuracy">{$accuracy}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.geo.setPerms(
    $is_public as xs:integer,
    $is_contact as xs:integer,
    $is_friend as xs:integer,
    $is_family as xs:integer,
    $photo_id as xs:integer)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.geo.setPerms">
                   <arg name="is_public">{$is_public}</arg>
                   <arg name="is_contact">{$is_contact}</arg>
                   <arg name="is_friend">{$is_friend}</arg>
                   <arg name="is_family">{$is_family}</arg>
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.licenses.getInfo()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.licenses.getInfo">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.licenses.setLicense(
    $photo_id as xs:string,
    $license_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.licenses.setLicense">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="license_id">{$license_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.notes.add(
    $photo_id as xs:string,
    $note_x as xs:integer,
    $note_y as xs:integer,
    $note_w as xs:integer,
    $note_h as xs:integer,
    $note_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.notes.add">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="note_x">{$note_x}</arg>
                   <arg name="note_y">{$note_y}</arg>
                   <arg name="note_w">{$note_w}</arg>
                   <arg name="note_h">{$note_h}</arg>
                   <arg name="note_text">{$note_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.notes.delete(
    $note_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.notes.delete">
                   <arg name="note_id">{$note_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.notes.edit(
    $note_id as xs:string,
    $note_x as xs:integer,
    $note_y as xs:integer,
    $note_w as xs:integer,
    $note_h as xs:integer,
    $note_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.notes.edit">
                   <arg name="note_id">{$note_id}</arg>
                   <arg name="note_x">{$note_x}</arg>
                   <arg name="note_y">{$note_y}</arg>
                   <arg name="note_w">{$note_w}</arg>
                   <arg name="note_h">{$note_h}</arg>
                   <arg name="note_text">{$note_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.transform.rotate(
    $photo_id as xs:string,
    $degrees as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photos.transform.rotate">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="degrees">{$degrees}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photos.upload.checkTickets(
    $tickets as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photos.upload.checkTickets">
                   <arg name="tickets">{$tickets}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.addPhoto(
    $photoset_id as xs:string,
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.addPhoto">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.create(
    $title as xs:string,
    $description as xs:string?,
    $degrees as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.create">
                   <arg name="title">{$title}</arg>
                   { if (empty($description))
                     then ()
                       else <arg name="description">{$description}</arg> }
                   <arg name="degrees">{$degrees}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.delete(
    $photoset_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.delete">
                   <arg name="photoset_id">{$photoset_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.editMeta(
    $photoset_id as xs:string,
    $title as xs:string,
    $description as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.editMeta">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   <arg name="title">{$title}</arg>
                   { if (empty($description))
                     then ()
                       else <arg name="description">{$description}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.editPhotos(
    $photoset_id as xs:string,
    $primary_photo_id as xs:string,
    $photo_ids as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.editPhotos">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   <arg name="primary_photo_id">{$primary_photo_id}</arg>
                   <arg name="photo_ids">{$photo_ids}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.getContext(
    $photo_id as xs:string,
    $photoset_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photosets.getContext">
                   <arg name="photo_id">{$photo_id}</arg>
                   <arg name="photoset_id">{$photoset_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.getInfo(
    $photoset_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photosets.getInfo">
                   <arg name="photoset_id">{$photoset_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.getList(
    $user_id as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photosets.getList">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.getPhotos(
    $photoset_id as xs:string,
    $extras as xs:string?,
    $privacy_filter as xs:integer?,
    $per_page as xs:integer?,
    $page as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photosets.getPhotos">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   { if (empty($extras))
                     then ()
                       else <arg name="extras">{$extras}</arg> }
                   { if (empty($privacy_filter))
                     then ()
                       else <arg name="privacy_filter">{$privacy_filter}</arg> }
                   { if (empty($per_page))
                     then ()
                       else <arg name="per_page">{$per_page}</arg> }
                   { if (empty($page))
                     then ()
                       else <arg name="page">{$page}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.orderSets(
    $photoset_ids as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.orderSets">
                   <arg name="photoset_ids">{$photoset_ids}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.removePhoto(
    $photoset_id as xs:string,
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.removePhoto">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.comments.addComment(
    $photoset_id as xs:string,
    $comment_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.comments.addComment">
                   <arg name="photoset_id">{$photoset_id}</arg>
                   <arg name="comment_text">{$comment_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.comments.deleteComment(
    $comment_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.comments.deleteComment">
                   <arg name="comment_id">{$comment_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.comments.editComment(
    $comment_id as xs:string,
    $comment_text as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         auth="true"
                         name="flickr.photosets.comments.editComment">
                   <arg name="comment_id">{$comment_id}</arg>
                   <arg name="comment_text">{$comment_text}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:photosets.comments.getList(
    $photoset_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.photosets.comments.getList">
                   <arg name="photoset_id">{$photoset_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:reflection.getMethodInfo(
    $method_name as xs:NCName)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.reflection.getMethodInfo">
                   <arg name="method_name">{$method_name}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:reflection.getMethods()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.reflection.getMethods">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getHotList(
    $period as xs:string?,
    $count as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getHotList">
                   { if (empty($period))
                     then ()
                       else <arg name="period">{$period}</arg> }
                   { if (empty($count))
                     then ()
                       else <arg name="count">{$count}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getListPhoto(
    $photo_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getListPhoto">
                   <arg name="photo_id">{$photo_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getListUser(
    $user_id as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getListUser">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getListUserPopular(
    $user_id as xs:string?,
    $count as xs:integer?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getListUserPopular">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                   { if (empty($count))
                     then ()
                       else <arg name="count">{$count}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getListUserRaw(
    $tag as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getListUserRaw">
                   { if (empty($tag))
                     then ()
                       else <arg name="tag">{$tag}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:tags.getRelated(
    $tag as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.tags.getRelated">
                   { if (empty($tag))
                     then ()
                       else <arg name="tag">{$tag}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:test.echo()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.test.echo">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:test.login()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.test.login">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:test.null()
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.test.null">
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:urls.getGroup(
    $group_id as xs:string)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.urls.getGroup">
                   <arg name="group_id">{$group_id}</arg>
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:urls.getUserPhotos(
    $user_id as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.urls.getUserPhotos">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:urls.getUserProfile(
    $user_id as xs:string?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.urls.getUserProfile">
                   { if (empty($user_id))
                     then ()
                       else <arg name="user_id">{$user_id}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:urls.lookupGroup(
    $url as xs:anyURI?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.urls.lookupGroup">
                   { if (empty($url))
                     then ()
                       else <arg name="url">{$url}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

declare function flickr:urls.lookupUser(
    $url as xs:anyURI?)
{
  let $method := <method xmlns="http://www.flickr.com/services/api/"
                         name="flickr.urls.lookupUser">
                   { if (empty($url))
                     then ()
                       else <arg name="url">{$url}</arg> }
                 </method>
  return
    flickr:_flickr($method)
};

