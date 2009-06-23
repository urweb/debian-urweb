#ifndef REQUEST_H
#define REQUEST_H

#include <sys/types.h>

#include "types.h"

typedef struct uw_rc *uw_request_context;

void uw_request_init(void *logger_data, uw_logger log_error, uw_logger log_debug);
void uw_sign(const char *in, char *out);

uw_request_context uw_new_request_context(void);
void uw_free_request_context(uw_request_context);

request_result uw_request(uw_request_context, uw_context,
                          char *method, char *path, char *query_string,
                          char *body, size_t body_len,
                          void (*on_success)(uw_context), void (*on_failure)(uw_context),
                          void *logger_data, uw_logger log_error, uw_logger log_debug,
                          int sock);

uw_context uw_request_new_context(void *logger_data, uw_logger log_error, uw_logger log_debug);

typedef struct {
  void *logger_data;
  uw_logger log_error, log_debug;
} loggers;

void *client_pruner(void *data);

#endif
