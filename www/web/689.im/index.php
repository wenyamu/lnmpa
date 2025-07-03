<!DOCTYPE html>
<html>
<body>

<h1>689 hk</h1>

</body>
</html>

<?php
echo "<h2>".$_SERVER['SERVER_SOFTWARE']."（".$_SERVER['SERVER_ADDR']."）</h2>";
echo "<h2>".php_sapi_name()."/". phpversion()."（".gethostbyname(gethostname())."）</h2>";
echo "<h2>".$_SERVER['HTTP_HOST']."</h2>";

$http_type = ((isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on') || (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')) ? 'https://' : 'http://';
$url = $http_type . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];//当前网址 
echo "<h2>".$url."</h2>";

echo "<h2>时区 (日期时间)<pre>".ini_get("date.timezone")." (".date("Y-m-d H:i:s").")</pre></h2>";

echo "<h2>你的ip<pre>".$_SERVER['REMOTE_ADDR']."<pre></h2>";
echo "<h3>php版本<pre>".phpversion()."<pre></h3>";//$_SERVER['PHP_VERSION']方式查询不一定有用

echo "<h3>php服务器容器名称<pre>".gethostname()."<pre></h3>";

echo "<h3>当前系统<pre>".php_uname("s")."<pre></h3>";

echo "<h3>系统详情<pre>".php_uname()."<pre></h3>";//php_uname("s")

echo "<br/>##########################<br/>";

//print_r(ini_get_all());//
echo "获取一个配置选项的值<br/>";
echo "post_max_size<pre>".ini_get("post_max_size")."</pre>";
echo "memory_limit<pre>".ini_get("memory_limit")."</pre>";
echo "upload_max_filesize<pre>".ini_get("upload_max_filesize")."</pre>";
echo "date.timezone<pre>".ini_get("date.timezone")."</pre>";

echo "<br/>##########################<br/>";

echo "获取已加载的PHP扩展的信息<pre>";
print_r(get_loaded_extensions());
echo "</pre>";
echo "<br/>##########################<br/>";
echo "返回系统的平均负载，返回一个包含最近 1 分钟、5 分钟和 15 分钟内的平均负载的数组";
$loadavg = sys_getloadavg();
echo "<pre>";
print_r($loadavg);
echo "</pre>";

echo '<h2>$_SERVER 常用参数<h2>';

echo "<h3>当前端口<pre>".$_SERVER['SERVER_PORT']."<pre></h3>";

echo "['HTTP_HOST']-----".$_SERVER['HTTP_HOST']."<br/>";

echo "['SERVER_NAME']-----".$_SERVER['SERVER_NAME']."<br/>";

phpinfo();
?>
