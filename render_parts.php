#!/usr/bin/php
<?php
defined( "ENT_XML1") or define("ENT_XML1",16);
function color_ansi2svg($col)
{
    $formats = explode(';',$col);
    $color_n = 7;
    $bold = false;
    foreach($formats as $format)
    {
        $format = (int)$format;
        if ( $format >= 30 && $format < 38 )
        {
            $color_n = $format-30;
        }
        else if ( $format == 1 )
            $bold = true;
    }
    
    if ( $bold )
    {
        switch($color_n)
        {
            case 0: return 'gray';
            case 1: return 'red';
            case 2: return 'lime';
            case 3: return 'yellow';
            case 4: return 'blue';
            case 5: return 'magenta';
            case 6: return 'cyan';
            case 7: return 'white';
        }
    }
    switch($color_n)
    {
        case 0: return 'black';
        case 1: return 'maroon';
        case 2: return 'green';
        case 3: return 'orange';
        case 4: return 'navy';
        case 5: return 'purple';
        case 6: return 'teal';
        case 7: return 'silver';
    }
    return "silver";
}

$dir = isset($argv[1]) ? $argv[1] : getcwd();
const COLORED_TEXT = 0;
const PLAIN_TEXT   = 1;
const SVG          = 2;
if ( !isset($argv[2]) )
    $output_type = COLORED_TEXT;
else if ( $argv[2] == 'nocolor' )
    $output_type = PLAIN_TEXT;
else if ( $argv[2] == 'svg' )
    $output_type = SVG;
    
    
$dir_files = scandir($dir);
$files = array();
$maxw = 0;
$maxh = 0;
foreach($dir_files as $file)
{
    if ( preg_match("/([0-9]+;)*[0-9]+/",$file) !== false )
    {
        $curr_file = file("$dir/$file",FILE_IGNORE_NEW_LINES);
        $files[$file] = $curr_file;
        foreach($curr_file as &$line)
        {
            $line = rtrim($line);
            $w = strlen($line);
            if ( $w> $maxw )
                $maxw = $w;
        }
        $h = count($curr_file);
        if ( $h > $maxh )
            $maxh = $h;
    }
}

$chars=array_fill(0,$maxh,array_fill(0,$maxw,null));

foreach ( $files as $color => $lines )
    for ( $i = 0; $i < count($lines); $i++ )
    {
        for ( $j = 0, $l = strlen($lines[$i]); $j < $l; $j++ )
        {
            if ( $lines[$i][$j] != ' ' )
                $chars[$i][$j] = array("color"=>$color,"char"=>$lines[$i][$j]);
        }
    }
    
if ( $output_type == SVG )
{
    $font_size = 12;
    $font_width = $font_size/2;
    echo "<?xml version='1.0' encoding='UTF-8' ?>\n";
    echo "<svg xmlns='http://www.w3.org/2000/svg' width='".($maxw*$font_width)."' height='".($maxh*$font_size)."'>\n";
    echo "<rect style='fill:black;stroke:none;' width='".($maxw*$font_width)."' height='".($maxh*$font_size)."' x='0' y='0' />\n";
    echo "<text y='0' x='0' style='font-family:monospace;font-size:${font_size}px;font-weight:bold;'>";
    $y = 0;
    
    
    foreach($chars as $line)
    {
        if ( $output_type == SVG )
        {
            $y += $font_size;
            $x = 0;
        }
        
        foreach($line as $char)
        {
            if ( !is_null($char) )
            {
                echo "<tspan x='$x' y='$y' style='fill:".color_ansi2svg($char['color']).";'>".
                        htmlspecialchars($char['char'],ENT_XML1)."</tspan>\n";
            }
            $x += $font_width;
        }
        echo "\n";
    }
    echo "</text></svg>";
}
else
{
    foreach($chars as $line)
    {
        if ( $output_type == SVG )
        {
            $y += $font_size;
            $x = 0;
        }
        
        foreach($line as $char)
        {
            if ( is_null($char) )
                echo ' ';
            else if ( $output_type == COLORED_TEXT )
                echo "\x1b[$char[color]m$char[char]";
            else
                echo $char['char'];
        }
        echo "\n";
    }
    if ( $output_type == COLORED_TEXT )
        echo "\x1b[0m\n";
}

