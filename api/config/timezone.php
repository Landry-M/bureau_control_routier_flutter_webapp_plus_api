<?php
/**
 * Configuration du fuseau horaire pour l'application
 * 
 * UTC+2 correspond à l'Afrique centrale (Cameroun, RDC, etc.)
 */

// Définir le fuseau horaire par défaut pour toute l'application
// Africa/Douala = UTC+1 (WAT - West Africa Time)
// Pour UTC+2, utiliser Africa/Johannesburg ou Africa/Cairo

// Pour le Cameroun (UTC+1) :
// date_default_timezone_set('Africa/Douala');

// Pour UTC+2 (Afrique centrale/est) :
date_default_timezone_set('Africa/Johannesburg');

// Alternative pour UTC+2 :
// date_default_timezone_set('Africa/Cairo');
// date_default_timezone_set('Africa/Maputo');
// date_default_timezone_set('Africa/Harare');

?>
