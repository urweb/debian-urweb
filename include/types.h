#ifndef URWEB_TYPES_H
#define URWEB_TYPES_H

#include <time.h>

typedef long long uw_Basis_int;
typedef double uw_Basis_float;
typedef char* uw_Basis_string;
typedef char uw_Basis_char;
typedef time_t uw_Basis_time;
typedef struct {
  size_t size;
  char *data;
} uw_Basis_blob;

struct __uws_0 {
};

typedef struct __uws_0 uw_unit;
typedef uw_unit uw_Basis_unit;

typedef enum uw_Basis_bool { uw_Basis_False, uw_Basis_True } uw_Basis_bool;

typedef struct uw_context *uw_context;

typedef uw_Basis_string uw_Basis_xhtml;
typedef uw_Basis_string uw_Basis_page;
typedef uw_Basis_string uw_Basis_xbody;
typedef uw_Basis_string uw_Basis_css_class;

typedef unsigned uw_Basis_client;
typedef struct {
  unsigned cli, chn;
} uw_Basis_channel;

typedef struct uw_Basis_file {
  uw_Basis_string name, type;
  uw_Basis_blob data;
} uw_Basis_file;

typedef enum { SUCCESS, FATAL, BOUNDED_RETRY, UNLIMITED_RETRY, RETURN_BLOB } failure_kind;

typedef enum { SERVED, KEEP_OPEN, FAILED } request_result;

typedef struct input *uw_input;

#define INTS_MAX 50
#define FLOATS_MAX 100
#define TIMES_MAX 100

typedef void (*uw_callback)(void *);
typedef void (*uw_logger)(void*, const char *fmt, ...);

#endif
