<?php
/**
 * Docker configuration for WordPress
 * 
 * This file should be used to override wp-config.php settings for Docker environment
 * You can copy this to wp-config.php or merge the settings manually
 */

// ** Database settings for Docker ** //
/** The name of the database for WordPress */
define( 'DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'nuxtcommerce_db' );

/** Database username */
define( 'DB_USER', getenv('WORDPRESS_DB_USER') ?: 'wordpress' );

/** Database password */
define( 'DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'wordpress' );

/** Database hostname */
define( 'DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'db:3306' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 * (Keep your existing keys from wp-config.php)
 */
define( 'AUTH_KEY',         'tCBU5acxv rOA HjV*##j{u|N>mX^)Jde8!XCzvpJj}M 3_AE ,^Op!qOxoRGOs=' );
define( 'SECURE_AUTH_KEY',  '2WZrj`EBiX$ONP (M692e&bv$s7[>X?Z<[xlpxcW1PD_,M=9|= 3Kt#l8dwNoI6v' );
define( 'LOGGED_IN_KEY',    'Gqf.^G_vJ#>oP)EXbZkzfW0 a,v>U=]?|[vrFzd<03Z4YtCWluN|yMduq2!?[c.!' );
define( 'NONCE_KEY',        'wZZ}Ay5RF`wnFdn^^._D>P%PbhTzyy%t}%.c9zI@rt&71,-z_|b+8@m{/gIR5-$n' );
define( 'AUTH_SALT',        '}S[jA|Z&Zlj96v33,!]22@MN5Jgi+wGjgpzt06wwi+UlK,)x;3BItSmxD)<{j5px' );
define( 'SECURE_AUTH_SALT', 'fdGb @Sn;^<gT(0D5t:N2Hoxw|EMq&~e;MaXqwx,7j,];LE+JTxlXU6>=1)YU67]' );
define( 'LOGGED_IN_SALT',   '69;Q*wt[4g3 a!dRdW+*nKeX}a+xq[o1I?_&s{T.]4/.{!-+b3yybzu?wPvr92{j' );
define( 'NONCE_SALT',       'mo1r`Qz=mjOdv;$CH F_r8P-R4}YG|}Ghq(aE*0Ov,rC#ma8W]DRzmt]okAr]f6u' );

/**#@-*/

/**
 * WordPress database table prefix.
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

set_time_limit(300); // 5 minutes
define('WP_MEMORY_LIMIT', '256M'); // Increase memory limit

// Enable Application Passwords for local development (without HTTPS requirement)
define( 'WP_ENVIRONMENT_TYPE', 'local' );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';

