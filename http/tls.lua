local openssl_ctx = require "openssl.ssl.context"
local openssl_pkey = require "openssl.pkey"

-- Detect if openssl was compiled with ALPN enabled
local has_alpn = openssl_ctx.new().setAlpnSelect ~= nil

-- Creates a cipher list suitable for passing to `setCipherList`
local function cipher_list(arr)
	return table.concat(arr, ":")
end

-- Cipher lists from Mozilla.
-- https://wiki.mozilla.org/Security/Server_Side_TLS
-- This list of ciphers should be kept up to date.

-- "Modern" cipher list
local modern_cipher_list = cipher_list {
	"ECDHE-RSA-AES128-GCM-SHA256";
	"ECDHE-ECDSA-AES128-GCM-SHA256";
	"ECDHE-RSA-AES256-GCM-SHA384";
	"ECDHE-ECDSA-AES256-GCM-SHA384";
	"DHE-RSA-AES128-GCM-SHA256";
	"DHE-DSS-AES128-GCM-SHA256";
	"kEDH+AESGCM";
	"ECDHE-RSA-AES128-SHA256";
	"ECDHE-ECDSA-AES128-SHA256";
	"ECDHE-RSA-AES128-SHA";
	"ECDHE-ECDSA-AES128-SHA";
	"ECDHE-RSA-AES256-SHA384";
	"ECDHE-ECDSA-AES256-SHA384";
	"ECDHE-RSA-AES256-SHA";
	"ECDHE-ECDSA-AES256-SHA";
	"DHE-RSA-AES128-SHA256";
	"DHE-RSA-AES128-SHA";
	"DHE-DSS-AES128-SHA256";
	"DHE-RSA-AES256-SHA256";
	"DHE-DSS-AES256-SHA";
	"DHE-RSA-AES256-SHA";
	"!aNULL";
	"!eNULL";
	"!EXPORT";
	"!DES";
	"!RC4";
	"!3DES";
	"!MD5";
	"!PSK";
}

-- "Intermediate" cipher list
local intermediate_cipher_list = cipher_list {
	"ECDHE-RSA-AES128-GCM-SHA256";
	"ECDHE-ECDSA-AES128-GCM-SHA256";
	"ECDHE-RSA-AES256-GCM-SHA384";
	"ECDHE-ECDSA-AES256-GCM-SHA384";
	"DHE-RSA-AES128-GCM-SHA256";
	"DHE-DSS-AES128-GCM-SHA256";
	"kEDH+AESGCM";
	"ECDHE-RSA-AES128-SHA256";
	"ECDHE-ECDSA-AES128-SHA256";
	"ECDHE-RSA-AES128-SHA";
	"ECDHE-ECDSA-AES128-SHA";
	"ECDHE-RSA-AES256-SHA384";
	"ECDHE-ECDSA-AES256-SHA384";
	"ECDHE-RSA-AES256-SHA";
	"ECDHE-ECDSA-AES256-SHA";
	"DHE-RSA-AES128-SHA256";
	"DHE-RSA-AES128-SHA";
	"DHE-DSS-AES128-SHA256";
	"DHE-RSA-AES256-SHA256";
	"DHE-DSS-AES256-SHA";
	"DHE-RSA-AES256-SHA";
	"ECDHE-RSA-DES-CBC3-SHA";
	"ECDHE-ECDSA-DES-CBC3-SHA";
	"EDH-RSA-DES-CBC3-SHA";
	"AES128-GCM-SHA256";
	"AES256-GCM-SHA384";
	"AES128-SHA256";
	"AES256-SHA256";
	"AES128-SHA";
	"AES256-SHA";
	"AES";
	"CAMELLIA";
	"DES-CBC3-SHA";
	"!aNULL";
	"!eNULL";
	"!EXPORT";
	"!DES";
	"!RC4";
	"!MD5";
	"!PSK";
	"!aECDH";
	"!EDH-DSS-DES-CBC3-SHA";
	"!KRB5-DES-CBC3-SHA";
}

-- Banned ciphers from https://http2.github.io/http2-spec/#BadCipherSuites
local function list_to_set(arr)
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end
local banned_ciphers = list_to_set {
	"TLS_NULL_WITH_NULL_NULL";
	"TLS_RSA_WITH_NULL_MD5";
	"TLS_RSA_WITH_NULL_SHA";
	"TLS_RSA_EXPORT_WITH_RC4_40_MD5";
	"TLS_RSA_WITH_RC4_128_MD5";
	"TLS_RSA_WITH_RC4_128_SHA";
	"TLS_RSA_EXPORT_WITH_RC2_CBC_40_MD5";
	"TLS_RSA_WITH_IDEA_CBC_SHA";
	"TLS_RSA_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_RSA_WITH_DES_CBC_SHA";
	"TLS_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_DH_DSS_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_DH_DSS_WITH_DES_CBC_SHA";
	"TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA";
	"TLS_DH_RSA_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_DH_RSA_WITH_DES_CBC_SHA";
	"TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_DHE_DSS_WITH_DES_CBC_SHA";
	"TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA";
	"TLS_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_DHE_RSA_WITH_DES_CBC_SHA";
	"TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_DH_anon_EXPORT_WITH_RC4_40_MD5";
	"TLS_DH_anon_WITH_RC4_128_MD5";
	"TLS_DH_anon_EXPORT_WITH_DES40_CBC_SHA";
	"TLS_DH_anon_WITH_DES_CBC_SHA";
	"TLS_DH_anon_WITH_3DES_EDE_CBC_SHA";
	"TLS_KRB5_WITH_DES_CBC_SHA";
	"TLS_KRB5_WITH_3DES_EDE_CBC_SHA";
	"TLS_KRB5_WITH_RC4_128_SHA";
	"TLS_KRB5_WITH_IDEA_CBC_SHA";
	"TLS_KRB5_WITH_DES_CBC_MD5";
	"TLS_KRB5_WITH_3DES_EDE_CBC_MD5";
	"TLS_KRB5_WITH_RC4_128_MD5";
	"TLS_KRB5_WITH_IDEA_CBC_MD5";
	"TLS_KRB5_EXPORT_WITH_DES_CBC_40_SHA";
	"TLS_KRB5_EXPORT_WITH_RC2_CBC_40_SHA";
	"TLS_KRB5_EXPORT_WITH_RC4_40_SHA";
	"TLS_KRB5_EXPORT_WITH_DES_CBC_40_MD5";
	"TLS_KRB5_EXPORT_WITH_RC2_CBC_40_MD5";
	"TLS_KRB5_EXPORT_WITH_RC4_40_MD5";
	"TLS_PSK_WITH_NULL_SHA";
	"TLS_DHE_PSK_WITH_NULL_SHA";
	"TLS_RSA_PSK_WITH_NULL_SHA";
	"TLS_RSA_WITH_AES_128_CBC_SHA";
	"TLS_DH_DSS_WITH_AES_128_CBC_SHA";
	"TLS_DH_RSA_WITH_AES_128_CBC_SHA";
	"TLS_DHE_DSS_WITH_AES_128_CBC_SHA";
	"TLS_DHE_RSA_WITH_AES_128_CBC_SHA";
	"TLS_DH_anon_WITH_AES_128_CBC_SHA";
	"TLS_RSA_WITH_AES_256_CBC_SHA";
	"TLS_DH_DSS_WITH_AES_256_CBC_SHA";
	"TLS_DH_RSA_WITH_AES_256_CBC_SHA";
	"TLS_DHE_DSS_WITH_AES_256_CBC_SHA";
	"TLS_DHE_RSA_WITH_AES_256_CBC_SHA";
	"TLS_DH_anon_WITH_AES_256_CBC_SHA";
	"TLS_RSA_WITH_NULL_SHA256";
	"TLS_RSA_WITH_AES_128_CBC_SHA256";
	"TLS_RSA_WITH_AES_256_CBC_SHA256";
	"TLS_DH_DSS_WITH_AES_128_CBC_SHA256";
	"TLS_DH_RSA_WITH_AES_128_CBC_SHA256";
	"TLS_DHE_DSS_WITH_AES_128_CBC_SHA256";
	"TLS_RSA_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA";
	"TLS_DHE_RSA_WITH_AES_128_CBC_SHA256";
	"TLS_DH_DSS_WITH_AES_256_CBC_SHA256";
	"TLS_DH_RSA_WITH_AES_256_CBC_SHA256";
	"TLS_DHE_DSS_WITH_AES_256_CBC_SHA256";
	"TLS_DHE_RSA_WITH_AES_256_CBC_SHA256";
	"TLS_DH_anon_WITH_AES_128_CBC_SHA256";
	"TLS_DH_anon_WITH_AES_256_CBC_SHA256";
	"TLS_RSA_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA";
	"TLS_PSK_WITH_RC4_128_SHA";
	"TLS_PSK_WITH_3DES_EDE_CBC_SHA";
	"TLS_PSK_WITH_AES_128_CBC_SHA";
	"TLS_PSK_WITH_AES_256_CBC_SHA";
	"TLS_DHE_PSK_WITH_RC4_128_SHA";
	"TLS_DHE_PSK_WITH_3DES_EDE_CBC_SHA";
	"TLS_DHE_PSK_WITH_AES_128_CBC_SHA";
	"TLS_DHE_PSK_WITH_AES_256_CBC_SHA";
	"TLS_RSA_PSK_WITH_RC4_128_SHA";
	"TLS_RSA_PSK_WITH_3DES_EDE_CBC_SHA";
	"TLS_RSA_PSK_WITH_AES_128_CBC_SHA";
	"TLS_RSA_PSK_WITH_AES_256_CBC_SHA";
	"TLS_RSA_WITH_SEED_CBC_SHA";
	"TLS_DH_DSS_WITH_SEED_CBC_SHA";
	"TLS_DH_RSA_WITH_SEED_CBC_SHA";
	"TLS_DHE_DSS_WITH_SEED_CBC_SHA";
	"TLS_DHE_RSA_WITH_SEED_CBC_SHA";
	"TLS_DH_anon_WITH_SEED_CBC_SHA";
	"TLS_RSA_WITH_AES_128_GCM_SHA256";
	"TLS_RSA_WITH_AES_256_GCM_SHA384";
	"TLS_DH_RSA_WITH_AES_128_GCM_SHA256";
	"TLS_DH_RSA_WITH_AES_256_GCM_SHA384";
	"TLS_DH_DSS_WITH_AES_128_GCM_SHA256";
	"TLS_DH_DSS_WITH_AES_256_GCM_SHA384";
	"TLS_DH_anon_WITH_AES_128_GCM_SHA256";
	"TLS_DH_anon_WITH_AES_256_GCM_SHA384";
	"TLS_PSK_WITH_AES_128_GCM_SHA256";
	"TLS_PSK_WITH_AES_256_GCM_SHA384";
	"TLS_RSA_PSK_WITH_AES_128_GCM_SHA256";
	"TLS_RSA_PSK_WITH_AES_256_GCM_SHA384";
	"TLS_PSK_WITH_AES_128_CBC_SHA256";
	"TLS_PSK_WITH_AES_256_CBC_SHA384";
	"TLS_PSK_WITH_NULL_SHA256";
	"TLS_PSK_WITH_NULL_SHA384";
	"TLS_DHE_PSK_WITH_AES_128_CBC_SHA256";
	"TLS_DHE_PSK_WITH_AES_256_CBC_SHA384";
	"TLS_DHE_PSK_WITH_NULL_SHA256";
	"TLS_DHE_PSK_WITH_NULL_SHA384";
	"TLS_RSA_PSK_WITH_AES_128_CBC_SHA256";
	"TLS_RSA_PSK_WITH_AES_256_CBC_SHA384";
	"TLS_RSA_PSK_WITH_NULL_SHA256";
	"TLS_RSA_PSK_WITH_NULL_SHA384";
	"TLS_RSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_RSA_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA256";
	"TLS_EMPTY_RENEGOTIATION_INFO_SCSV";
	"TLS_ECDH_ECDSA_WITH_NULL_SHA";
	"TLS_ECDH_ECDSA_WITH_RC4_128_SHA";
	"TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA";
	"TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA";
	"TLS_ECDHE_ECDSA_WITH_NULL_SHA";
	"TLS_ECDHE_ECDSA_WITH_RC4_128_SHA";
	"TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA";
	"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA";
	"TLS_ECDH_RSA_WITH_NULL_SHA";
	"TLS_ECDH_RSA_WITH_RC4_128_SHA";
	"TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDH_RSA_WITH_AES_128_CBC_SHA";
	"TLS_ECDH_RSA_WITH_AES_256_CBC_SHA";
	"TLS_ECDHE_RSA_WITH_NULL_SHA";
	"TLS_ECDHE_RSA_WITH_RC4_128_SHA";
	"TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA";
	"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA";
	"TLS_ECDH_anon_WITH_NULL_SHA";
	"TLS_ECDH_anon_WITH_RC4_128_SHA";
	"TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDH_anon_WITH_AES_128_CBC_SHA";
	"TLS_ECDH_anon_WITH_AES_256_CBC_SHA";
	"TLS_SRP_SHA_WITH_3DES_EDE_CBC_SHA";
	"TLS_SRP_SHA_RSA_WITH_3DES_EDE_CBC_SHA";
	"TLS_SRP_SHA_DSS_WITH_3DES_EDE_CBC_SHA";
	"TLS_SRP_SHA_WITH_AES_128_CBC_SHA";
	"TLS_SRP_SHA_RSA_WITH_AES_128_CBC_SHA";
	"TLS_SRP_SHA_DSS_WITH_AES_128_CBC_SHA";
	"TLS_SRP_SHA_WITH_AES_256_CBC_SHA";
	"TLS_SRP_SHA_RSA_WITH_AES_256_CBC_SHA";
	"TLS_SRP_SHA_DSS_WITH_AES_256_CBC_SHA";
	"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256";
	"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384";
	"TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256";
	"TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384";
	"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256";
	"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384";
	"TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256";
	"TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384";
	"TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256";
	"TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384";
	"TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256";
	"TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384";
	"TLS_ECDHE_PSK_WITH_RC4_128_SHA";
	"TLS_ECDHE_PSK_WITH_3DES_EDE_CBC_SHA";
	"TLS_ECDHE_PSK_WITH_AES_128_CBC_SHA";
	"TLS_ECDHE_PSK_WITH_AES_256_CBC_SHA";
	"TLS_ECDHE_PSK_WITH_AES_128_CBC_SHA256";
	"TLS_ECDHE_PSK_WITH_AES_256_CBC_SHA384";
	"TLS_ECDHE_PSK_WITH_NULL_SHA";
	"TLS_ECDHE_PSK_WITH_NULL_SHA256";
	"TLS_ECDHE_PSK_WITH_NULL_SHA384";
	"TLS_RSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_RSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_DH_DSS_WITH_ARIA_128_CBC_SHA256";
	"TLS_DH_DSS_WITH_ARIA_256_CBC_SHA384";
	"TLS_DH_RSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_DH_RSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_DHE_DSS_WITH_ARIA_128_CBC_SHA256";
	"TLS_DHE_DSS_WITH_ARIA_256_CBC_SHA384";
	"TLS_DHE_RSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_DHE_RSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_DH_anon_WITH_ARIA_128_CBC_SHA256";
	"TLS_DH_anon_WITH_ARIA_256_CBC_SHA384";
	"TLS_ECDHE_ECDSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_ECDHE_ECDSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_ECDH_ECDSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_ECDH_ECDSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_ECDHE_RSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_ECDHE_RSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_ECDH_RSA_WITH_ARIA_128_CBC_SHA256";
	"TLS_ECDH_RSA_WITH_ARIA_256_CBC_SHA384";
	"TLS_RSA_WITH_ARIA_128_GCM_SHA256";
	"TLS_RSA_WITH_ARIA_256_GCM_SHA384";
	"TLS_DH_RSA_WITH_ARIA_128_GCM_SHA256";
	"TLS_DH_RSA_WITH_ARIA_256_GCM_SHA384";
	"TLS_DH_DSS_WITH_ARIA_128_GCM_SHA256";
	"TLS_DH_DSS_WITH_ARIA_256_GCM_SHA384";
	"TLS_DH_anon_WITH_ARIA_128_GCM_SHA256";
	"TLS_DH_anon_WITH_ARIA_256_GCM_SHA384";
	"TLS_ECDH_ECDSA_WITH_ARIA_128_GCM_SHA256";
	"TLS_ECDH_ECDSA_WITH_ARIA_256_GCM_SHA384";
	"TLS_ECDH_RSA_WITH_ARIA_128_GCM_SHA256";
	"TLS_ECDH_RSA_WITH_ARIA_256_GCM_SHA384";
	"TLS_PSK_WITH_ARIA_128_CBC_SHA256";
	"TLS_PSK_WITH_ARIA_256_CBC_SHA384";
	"TLS_DHE_PSK_WITH_ARIA_128_CBC_SHA256";
	"TLS_DHE_PSK_WITH_ARIA_256_CBC_SHA384";
	"TLS_RSA_PSK_WITH_ARIA_128_CBC_SHA256";
	"TLS_RSA_PSK_WITH_ARIA_256_CBC_SHA384";
	"TLS_PSK_WITH_ARIA_128_GCM_SHA256";
	"TLS_PSK_WITH_ARIA_256_GCM_SHA384";
	"TLS_RSA_PSK_WITH_ARIA_128_GCM_SHA256";
	"TLS_RSA_PSK_WITH_ARIA_256_GCM_SHA384";
	"TLS_ECDHE_PSK_WITH_ARIA_128_CBC_SHA256";
	"TLS_ECDHE_PSK_WITH_ARIA_256_CBC_SHA384";
	"TLS_ECDHE_ECDSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_ECDHE_ECDSA_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_ECDH_ECDSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_ECDH_ECDSA_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_ECDHE_RSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_ECDHE_RSA_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_ECDH_RSA_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_ECDH_RSA_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_RSA_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_RSA_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_DH_RSA_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_DH_RSA_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_DH_DSS_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_DH_DSS_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_DH_anon_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_DH_anon_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_ECDH_ECDSA_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_ECDH_ECDSA_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_ECDH_RSA_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_ECDH_RSA_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_PSK_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_PSK_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_RSA_PSK_WITH_CAMELLIA_128_GCM_SHA256";
	"TLS_RSA_PSK_WITH_CAMELLIA_256_GCM_SHA384";
	"TLS_PSK_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_PSK_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_DHE_PSK_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_DHE_PSK_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_RSA_PSK_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_RSA_PSK_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_ECDHE_PSK_WITH_CAMELLIA_128_CBC_SHA256";
	"TLS_ECDHE_PSK_WITH_CAMELLIA_256_CBC_SHA384";
	"TLS_RSA_WITH_AES_128_CCM";
	"TLS_RSA_WITH_AES_256_CCM";
	"TLS_RSA_WITH_AES_128_CCM_8";
	"TLS_RSA_WITH_AES_256_CCM_8";
	"TLS_PSK_WITH_AES_128_CCM";
	"TLS_PSK_WITH_AES_256_CCM";
	"TLS_PSK_WITH_AES_128_CCM_8";
	"TLS_PSK_WITH_AES_256_CCM_8";
}

local function new_client_context()
	local ctx = openssl_ctx.new("TLSv1_2", false)
	ctx:setCipherList(modern_cipher_list)
	ctx:setOptions(openssl_ctx.OP_NO_COMPRESSION+openssl_ctx.OP_SINGLE_ECDH_USE)
	ctx:setEphemeralKey(openssl_pkey.new{ type = "EC", curve = "prime256v1" })
	return ctx
end

local function new_server_context()
	local ctx = openssl_ctx.new("TLSv1_2", true)
	ctx:setCipherList(modern_cipher_list)
	ctx:setOptions(openssl_ctx.OP_NO_COMPRESSION+openssl_ctx.OP_SINGLE_ECDH_USE)
	ctx:setEphemeralKey(openssl_pkey.new{ type = "EC", curve = "prime256v1" })
	return ctx
end

return {
	has_alpn = has_alpn;
	modern_cipher_list = modern_cipher_list;
	intermediate_cipher_list = intermediate_cipher_list;
	banned_ciphers = banned_ciphers;
	new_client_context = new_client_context;
	new_server_context = new_server_context;
}
