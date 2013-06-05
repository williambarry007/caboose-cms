<h1>Caboose CMS</h1>
<p>Caboose is a simple yet flexible and powerful content management system that runs 
on top of ruby on rails.  It handles users, roles, permissions, and the login process.
In addition, it handles content pages and their URLs.  It has a layout system that 
allows a developer to easily customize the look and feel of each page.</p>

<ul>
<li><a href='#installation'>Installation</a></li>
<li><a href='#layouts'>Layouts</a></li>
<li><a href='#plugins'>Plugins</a></li>

<a name='installation'></a><h2>Installation</h2>
<p>Install the caboose-cms gem:</p>
<pre>
$ gem install caboose-cms
</pre>
<p>Create a new rails app configured to use caboose:</p>
<pre>
$ caboose new my_caboose_app
</pre>
<p>Now go create a local MySQL database called my_caboose_app_development. Then let caboose install the database:</p>
<pre>
$ cd my_caboose_app
$ rake caboose:db
</pre>
<p>That's it! To test it out, start your rails server:</p>
<pre>
$ rails server
</pre>
<p>And go check out http://localhost:3000</p>

<a name='layouts'></a><h2>Layouts</h2>
<p>Caboose already handles the page editing process, but you need to be able to 
control the layout for each of those pages.  You do that with layouts.  Caboose 
has a simple layout system.  You control which layout each page uses.  There are three options:
<dl>
  <dt>Default layout:</dt>
  <dd><p>The layout that any page by default will use if any other layout options are not set.  This layout resides in the <code>layout_default.html.erb</code> file.</p></dd>
  <dt>Per page layout:</dt>
  <dd>
    <p>Just create a new layout called <code>layout_&lt;page_id&gt;.html.erb</code>.</p>
    <p>Example: <code>layout_37.html.erb</code></p>
  </dd>
  <dt>Per type layout:</dt>
  <dd>
    <p>If you need multiple pages to use a common layout, just create a layout with a name.</p>
    <p>Examples: <code>layout_about.html.erb</code>, <code>layout_listing.html.erb</code></p>
  </dd>
</dl>
<p>For each layout, a few things must exist in the layout for it to work properly with Caboose.
You must include the following:</p>
<ul>
  <li>
    <p>CSS and CSRF in the head:</p>
    <pre>
    &lt;%= yield :css %&gt;
    &lt;%= csrf_meta_tags %&gt;
    </pre>
  </li>
  <li>
    <p>The top nav login/control panel link:</p>
    <pre>
    &lt;%= render :partial => 'layouts/caboose/top_nav' %&gt;
    </pre>
  </li>
  <li>
    <p>The top nav login/control panel link:</p>
    <pre>
    &lt;%= render :partial => 'layouts/caboose/top_nav' %&gt;
    </pre>
  </li>
  <li>
    <p>The station and javascript in the footer:</p>
    <pre>
    &lt;%= render :partial => 'layouts/caboose/station' %&gt;
    &lt;%= yield :js %&gt;
    </pre>
  </li>
</ul>
<p>You have access to the <code>@page</code> object in the layout.  Here's a bare-bones example of all the elements:

<pre>
&lt;!DOCTYPE html&gt;
&lt;html&gt;
&lt;head&gt;
&lt;title&gt;My App&lt;/title&gt;
&lt;%= yield :css %&gt;
&lt;%= csrf_meta_tags %&gt;
&lt;/head&gt;
&lt;body;&gt;
&lt;%= render :partial =&gt; 'layouts/caboose/top_nav' %&gt;

&lt;h1&gt;&lt;%= raw @page.title %&gt;&lt;/h1&gt;
&lt;%= raw @page.content %&gt;  

&lt;%= render :partial =&gt; 'layouts/caboose/station' %&gt;
&lt;%= yield :js %&gt;
&lt;/body&gt;
&lt;/html&gt;
</pre>

<a name='plugins'><h2>Plugins</h2>
<p>To add new functionality to the Caboose station, extend the CaboosePlugin
object and override the methods you'd like to implement.  The existing hooks
are the following:</p>

<dl>
  <dt><code>String page_content(String str)</code></dt>
  <dd>Given the page content string, manipulate and return.</dd>  
  <dt><code>Array admin_nav(Array arr)</code></dt>
  <dd>Add items to the navigation that appears in the caboose station.</dd>
</dl>
