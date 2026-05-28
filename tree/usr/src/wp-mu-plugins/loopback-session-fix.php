<?php
/**
 * Plugin Name: Loopback Session-Lock Fix
 * Description: Strip the PHP session cookie (PHPSESSID) from WordPress's OWN
 *  internal loopback HTTP requests so they don't deadlock on the file-based
 *  session lock held by the parent request.
 *
 *  Bundled in the custom-wordpress base image and installed into each site's
 *  wp-content/mu-plugins by entrypoint-override.sh.
 *
 *  Why: PHP `files` sessions hold an exclusive lock for the whole request.
 *  CiviCRM (and some other plugins) call session_start() on admin requests, so
 *  the parent (e.g. the Site Health page, or the block/site editor) holds the
 *  lock. WordPress then makes an authenticated server-side loopback (Site
 *  Health "REST API" test: GET /wp-json/wp/v2/types/post?context=edit) and
 *  passes the browser's whole cookie jar, including PHPSESSID. The loopback
 *  lands on a fresh php-fpm worker which calls session_start() with that same
 *  PHPSESSID and blocks on the locked session file -- while the parent is
 *  blocked up to 10s waiting on the loopback. Deadlock => "cURL error 28:
 *  timed out ... 0 bytes received". Raising pm.max_children does NOT help
 *  (it's a lock, not a worker shortage).
 *
 *  Fix: WordPress authenticates the loopback via its own cookies
 *  (wordpress_logged_in_*) + X-WP-Nonce, NOT via PHPSESSID -- only CiviCRM uses
 *  the PHP session. Removing PHPSESSID from same-host loopback requests lets
 *  the loopback get a throwaway session (no lock contention) while staying
 *  fully authenticated. External HTTP requests are untouched.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_filter(
	'http_request_args',
	function ( $args, $url ) {
		// Only act on loopbacks to our own host; leave external calls alone.
		$home   = wp_parse_url( home_url() );
		$target = wp_parse_url( $url );
		if ( empty( $target['host'] ) || empty( $home['host'] )
			|| 0 !== strcasecmp( $target['host'], $home['host'] ) ) {
			return $args;
		}

		if ( empty( $args['cookies'] ) || ! is_array( $args['cookies'] ) ) {
			return $args;
		}

		$session_name = session_name();
		if ( ! $session_name ) {
			$session_name = 'PHPSESSID';
		}

		// Cookies may be an assoc array (name=>value) or WP_Http_Cookie objects.
		foreach ( $args['cookies'] as $key => $cookie ) {
			if ( is_string( $key ) && 0 === strcasecmp( $key, $session_name ) ) {
				unset( $args['cookies'][ $key ] );
			} elseif ( $cookie instanceof WP_Http_Cookie
				&& 0 === strcasecmp( (string) $cookie->name, $session_name ) ) {
				unset( $args['cookies'][ $key ] );
			}
		}

		return $args;
	},
	10,
	2
);
