#!/usr/bin/php
<?php
defined( "ENT_XML1") or define("ENT_XML1",16);

class Color
{
	public $color = 7;
	public $bright = false;

	function __construct($color, $bright=false)
	{
		$this->color = $color;
		$this->bright = $bright;
	}

	static $names_to_int = array(
		'black'   => 0,
		'red'     => 1,
		'green'   => 2,
		'yellow'  => 3,
		'blue'    => 4,
		'magenta' => 5,
		'cyan'    => 6,
		'white'   => 7
	);

	static function from_ansi($col)
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
			else if ( $format >= 90 && $format < 98 )
			{
				$color_n = $format-90;
				$bold = true;
			}
			else if ( $format == 1 )
			{
				$bold = true;
			}
		}

		return new Color( $color_n, $bold );
	}

}

interface ColorOutput
{
	function begin();
	function end();
	function begin_line();
	function end_line();
	function character( $char );

}

class SvgColorOutput implements ColorOutput
{
	private $font_size;
    private $font_width;
	private $width, $height;
	private $y = 0, $x = 0;

	function __construct($width_in_characters, $height_in_characters, $font_size = 12)
	{
		$this->font_size = $font_size;
		$this->font_width = $font_size/2;
		$this->width = $width_in_characters * $this->font_width;
		$this->height = $height_in_characters * $this->font_size;
	}

	function begin()
	{
		echo "<?xml version='1.0' encoding='UTF-8' ?>\n";
		echo "<svg xmlns='http://www.w3.org/2000/svg' width='{$this->width}' height='{$this->height}'>\n";
		echo "<rect style='fill:black;stroke:none;' width='{$this->width}' height='{$this->height}' x='0' y='0' />\n";
		echo "<text y='0' x='0' style='font-family:monospace;font-size:{$this->font_size}px;font-weight:bold;'>";
	}

	function end()
	{
		echo "</text></svg>";
	}

	function begin_line()
	{
        $this->y += $this->font_size;
        $this->x = 0;
	}

	function end_line()
	{
        echo "\n";
	}

	function character( $char )
	{
		if ( !is_null($char) )
		{
			echo "<tspan x='{$this->x}' y='{$this->y}' style='fill:".$this->color($char['color']).";'>".
					htmlspecialchars($char['char'],ENT_XML1)."</tspan>\n";
		}
		$this->x += $this->font_width;
	}

	function color( Color $color )
	{
		if ( $color->bright )
		{
			switch( $color->color )
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
		switch( $color->color )
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
}

class PlaintextColorOutput implements ColorOutput
{
	function begin() {}
	function end() {}
	function begin_line() {}
	function end_line()
	{
		echo "\n";
	}

	function character( $char )
	{
		if ( is_null($char) )
			echo ' ';
		else
			echo $this->color($char['color']).$this->escape($char['char']);
	}

	function color( Color $color )
	{
		return "";
	}

	function escape( $char )
	{
		return $char;
	}

}

class IRCColorOutput extends PlaintextColorOutput
{
	private $width_in_characters;
	private $x;

	function __construct( $width_in_characters )
	{
		$this->width_in_characters = $width_in_characters;
	}

	function begin_line()
	{
		echo "\x0301,01";
		$this->x = 0;
	}

	function end_line()
	{
		echo str_repeat(' ',$this->width_in_characters-$this->x)."\x03";
		echo "\n";
	}

	function character( $char )
	{
		$this->x++;
		parent::character( $char );
	}

	function color( Color $color )
	{
		return "\x03".$this->color_code($color);
	}

	function color_code( Color $color )
	{
		if ( $color->bright )
		{
			switch( $color->color )
			{
				case 0: return '14';
				case 1: return '04';
				case 2: return '09';
				case 3: return '08';
				case 4: return '12';
				case 5: return '13';
				case 6: return '11';
				case 7: return '00';
			}
		}
		switch( $color->color )
		{
			case 0: return '01';
			case 1: return '05';
			case 2: return '03';
			case 3: return '07';
			case 4: return '02';
			case 5: return '06';
			case 6: return '10';
			case 7: return '15';
		}
		return '15';
	}

}
class AnsiColorOutput extends PlainTextColorOutput
{
	function end()
	{
        echo "\x1b[0m\n";
	}

	function color( Color $color )
	{
		return "\x1b[".$this->color_code($color)."m";
	}

	function color_code( Color $color )
	{
		$bold = $color->bright ? "1" : "22";
		return (30+$color->color).";{$bold}";
	}

}
class BashColorOutput extends AnsiColorOutput
{
	function begin()
	{
        echo "#!/bin/bash\n";
        echo "read -r -d '' Heredoc_var <<'Heredoc_var'\n\\x1b[0m";
	}

	function end()
	{
        echo "\\x1b[0m\nHeredoc_var\necho -e \"\$Heredoc_var\"\n";
	}

	function escape( $char )
	{
		return $char == '\\' ? '\\\\' : $char;
	}

	function color( Color $color )
	{
		return "\\x1b[".$this->color_code($color)."m";
	}
}

$dir = isset($argv[1]) ? $argv[1] : getcwd();
const COLORED_TEXT = 0;
const PLAIN_TEXT   = 1;
const SVG          = 2;
const BASH         = 3;
const IRC_TEXT     = 4;
if ( !isset($argv[2]) )
    $output_type = COLORED_TEXT;
else if ( $argv[2] == 'nocolor' )
    $output_type = PLAIN_TEXT;
else if ( $argv[2] == 'svg' )
    $output_type = SVG;
else if ( $argv[2] == 'bash' )
    $output_type = BASH;
else if ( $argv[2] == 'irc' )
    $output_type = IRC_TEXT;
    
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
                $chars[$i][$j] = array("color"=>Color::from_ansi($color),"char"=>$lines[$i][$j]);
        }
    }

/// \todo factory
if ( $output_type == SVG )
{
	$output = new SvgColorOutput($maxw, $maxh);
}
else if ( $output_type == BASH )
{
	$output = new BashColorOutput();
}
else if ( $output_type == IRC_TEXT )
{
	$output = new IrcColorOutput($maxw);
}
else if ( $output_type == COLORED_TEXT )
{
	$output = new AnsiColorOutput();
}
else
{
	$output = new PlainTextColorOutput();
}

$output->begin();

foreach($chars as $line)
{
	$output->begin_line();
	foreach($line as $char)
	{
		$output->character( $char );
	}
	$output->end_line();
}

$output->end();


