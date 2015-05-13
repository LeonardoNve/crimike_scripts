<?php
// so we can track exec time
$time_start = microtime(true); 

// for table drawing, should really be in its own class but oh well
const SPACING_X   = 1;
const SPACING_Y   = 0;
const JOINT_CHAR  = '+';
const LINE_X_CHAR = '-';
const LINE_Y_CHAR = '|';

function draw_table($table)
{
 
    $nl              = "\n";
    $columns_headers = columns_headers($table);
    $columns_lengths = columns_lengths($table, $columns_headers);
    $row_separator   = row_seperator($columns_lengths);
    $row_spacer      = row_spacer($columns_lengths);
    $row_headers     = row_headers($columns_headers, $columns_lengths);
 
    echo $row_separator . $nl;
    echo str_repeat($row_spacer . $nl, SPACING_Y);
    echo $row_headers . $nl;
    echo str_repeat($row_spacer . $nl, SPACING_Y);
    echo $row_separator . $nl;
    echo str_repeat($row_spacer . $nl, SPACING_Y);
    foreach ($table as $row_cells) {
        $row_cells = row_cells($row_cells, $columns_headers, $columns_lengths);
        echo $row_cells . $nl;
        echo str_repeat($row_spacer . $nl, SPACING_Y);
    }
    echo $row_separator . $nl;
}
 
function columns_headers($table)
{
    return array_keys(reset($table));
}
 
function columns_lengths($table, $columns_headers)
{
    $lengths = [];
    foreach ($columns_headers as $header) {
        $header_length = strlen($header);
        $max           = $header_length;
        foreach ($table as $row) {
            $length = strlen($row[$header]);
            if ($length > $max) {
                $max = $length;
            }
        }
 
        if (($max % 2) != ($header_length % 2)) {
            $max += 1;
        }
 
        $lengths[$header] = $max;
    }
 
    return $lengths;
}
 
function row_seperator($columns_lengths)
{
    $row = '';
    foreach ($columns_lengths as $column_length) {
        $row .= JOINT_CHAR . str_repeat(LINE_X_CHAR, (SPACING_X * 2) + $column_length);
    }
    $row .= JOINT_CHAR;
 
    return $row;
}
 
function row_spacer($columns_lengths)
{
    $row = '';
    foreach ($columns_lengths as $column_length) {
        $row .= LINE_Y_CHAR . str_repeat(' ', (SPACING_X * 2) + $column_length);
    }
    $row .= LINE_Y_CHAR;
 
    return $row;
}
 
function row_headers($columns_headers, $columns_lengths)
{
    $row = '';
    foreach ($columns_headers as $header) {
        $row .= LINE_Y_CHAR . str_pad($header, (SPACING_X * 2) + $columns_lengths[$header], ' ', STR_PAD_BOTH);
    }
    $row .= LINE_Y_CHAR;
 
    return $row;
}
 
function row_cells($row_cells, $columns_headers, $columns_lengths)
{
    $row = '';
    foreach ($columns_headers as $header) {
        $row .= LINE_Y_CHAR . str_repeat(' ', SPACING_X) . str_pad($row_cells[$header], SPACING_X + $columns_lengths[$header], ' ', STR_PAD_RIGHT);
    }
    $row .= LINE_Y_CHAR;
 
    return $row;
}
?>

<?php
    // START----------------------------
    define("IP", 0);
    define("NAME_DATA", 1);
    define("FLAGS", 2);
    
    // i'm laazy (this should have its own file)
    class workstation {
        public $domain_name = "";
        public $hostname = "";
        public $fqdn = "";
        public $ip = ""; 
        public $is_dc = false;
        public $is_dm = false;
        public $is_wg = false;
        public $has_children = false;
        public $has_msbrowse = false;
        public $os = "";
        
        public function __construct($ip) {
            $this->ip = $ip;
        }
    }

    // initialize
    $x = 0;
    $i = 0;
    $workstation = array();
    $table = array();
    $processed_ips = array();
    
    // main
    if(empty($argv[1]))
        die("Please specify an IP or IP range to scan!\n");

    $target = escapeshellcmd($argv[1]);
    
    // is this a range? if so, get inital IP preceeding the range separator
    if($ip = strstr($target, "/", true)){
        $target = $ip;
    }else if($ip = strstr($target, "-", true)){
        $target = $ip;
    }
    
    // is it a valid IP?
    if(!filter_var($target, FILTER_VALIDATE_IP)) {
        die("Not a valid IP address!\n");
    }else{
        // restore singular IP to range
        $target = escapeshellcmd($argv[1]);
    }
    
    // perform nbtscan and parse results
    $nbtscan_results = shell_exec("nbtscan -vv -h -s \":\" -r $target");
    $nbtscan_results = explode("\n", $nbtscan_results);
    if(!empty($nbtscan_results) && count($nbtscan_results) > 1){ // there is always one empty array element, so 
        array_pop($nbtscan_results); // the last element of the array is always empty
        foreach($nbtscan_results as $line){            
            $ip = explode(":", $line)[IP];    

            // is this a new IP address that we haven't processed?
            if(!in_array($ip, $processed_ips)){
                $i++;
                $processed_ips[$i] = $ip;
                $workstation[$i] = new workstation($ip);
                
                echo "Processing $ip\n";
                
                // get fqdn and OS while we're here (via SMBClient and LDAP)
                $output = shell_exec("ldapsearch -x -h $ip -p 389 -s base | grep -i dnsHostName");
                $workstation[$i]->fqdn = strtolower(trim(substr(strstr($output, ":", false), 1)));
                $output = shell_exec("smbclient //$ip/ipc\$ -N -c 'q' 2>&1 | grep -i server=");
                $workstation[$i]->os = trim(stristr($output, "server=", false));
                $workstation[$i]->os = substr($workstation[$i]->os, 8, -1);
            }else{
                // we've processed this IP, next!
                continue;
            }

            // parse all data for this IP
            foreach($nbtscan_results as $line_secondary){
                // make sure we process the right IP
                $data = explode(":", $line_secondary);
                if($data[IP] != $ip)
                    continue;

                // get hostname
                if($workstation[$i]->hostname == "")
                    $workstation[$i]->hostname = rtrim($data[NAME_DATA]);

                // check whether domain controller, if applicable
                if($workstation[$i]->is_dc == false)
                    $workstation[$i]->is_dc = stristr($data[FLAGS], "Domain Controllers") ? true : false;

                // get domain name where applicable
                if($workstation[$i]->domain_name == "" && stristr($data[FLAGS], "Domain name"))
                    $workstation[$i]->domain_name = rtrim($data[NAME_DATA]);

                // has msbrowse (used to distinguish between domain, wg)
                if($workstation[$i]->has_msbrowse == false)
                    $workstation[$i]->has_msbrowse = stristr($data[NAME_DATA], "MSBROWSE") ? true : false;
            }

            // using the information above, we can populate remaining fields...
            // dc with msbrowse = dc has children
            if($workstation[$i]->is_dc && $workstation[$i]->has_msbrowse)
                $workstation[$i]->has_children = true;

            // not a dc and no msbrowse = part of domain
            if($workstation[$i]->is_dc === false && $workstation[$i]->has_msbrowse === false)
                $workstation[$i]->is_dm = true;

            // has msbrowse but not a dc = workgroup OR domain name = WORKGROUP (which is reserved)
            if((!$workstation[$i]->is_dc && $workstation[$i]->has_msbrowse) || $workstation[$i]->domain_name == "WORKGROUP"){
                $workstation[$i]->is_wg = true;
                $workstation[$i]->is_dm = false;
            }
        }
    }
   
    
    echo "\n";
    
    // output domain controllers and members first
    foreach($workstation as $box){
        if($box->is_wg == true)
            continue;
        
        // hostname
        $table[$x]['IP'] = $box->ip;
        $table[$x]['hostname'] = $box->hostname;
        
	if($box->is_dc)
            $table[$x]['type'] = "DC" . (($box->has_children) ? " (parent)" : "");
        else if($box->is_dm)
            $table[$x]['type'] = "DM";
        
        $table[$x]['Domain/WG'] = $box->domain_name;
        $table[$x]['FQDN'] = (!empty($box->fqdn)) ? $box->fqdn : "N/A";
        $table[$x]['OS'] = (!empty($box->os)) ? $box->os : "N/A";
        
        $x++;
    }
    
    // output workgroups
	if(!empty($workstation)){
	    foreach($workstation as $box){
		if($box->is_wg == false)
		    continue;
		
		// hostname
		$table[$x]['IP'] = $box->ip;
		$table[$x]['hostname'] = $box->hostname;
		$table[$x]['type'] = "Workgroup";    
		
		$table[$x]['Domain/WG'] = $box->domain_name;
		$table[$x]['FQDN'] = (!empty($box->fqdn)) ? $box->fqdn : "N/A";
		$table[$x]['OS'] = (!empty($box->os)) ? $box->os : "N/A";
		
		$x++;
	    }    
	    
	    // draw our table
	    draw_table($table);
	}
    
    // get exec time
    $time_end = microtime(true);
    $execution_time = ($time_end - $time_start);
    
    // output execution time of the script
    echo "Total Execution Time: " . round($execution_time, 2) . " seconds\n";