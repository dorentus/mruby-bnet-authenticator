#include <stdlib.h>
#include "mruby.h"
#include "mruby/string.h"
#include "bigd.h"

static mrb_value
mrb_mod_exp(mrb_state *mrb, mrb_value self)
{
  mrb_value value, exp, mod;
  mrb_get_args(mrb, "SSS", &value, &exp, &mod);

  const char *v_str, *exp_str, *mod_str;
  v_str = mrb_string_value_cstr(mrb, &value);
  exp_str = mrb_string_value_cstr(mrb, &exp);
  mod_str = mrb_string_value_cstr(mrb, &mod);

  BIGD v_bd, exp_bd, mod_bd, result_bd;
  v_bd = bdNew();
  exp_bd = bdNew();
  mod_bd = bdNew();
  result_bd = bdNew();

  bdConvFromHex(v_bd, v_str);
  bdConvFromHex(exp_bd, exp_str);
  bdConvFromHex(mod_bd, mod_str);

  bdModExp(result_bd, v_bd, exp_bd, mod_bd);

  bdFree(&v_bd);
  bdFree(&exp_bd);
  bdFree(&mod_bd);

  size_t nchars = bdConvToHex(result_bd, NULL, 0);
  char *result_str = malloc(nchars + 1);
  bdConvToHex(result_bd, result_str, nchars + 1);

  bdFree(&result_bd);

  mrb_value result;
  result = mrb_str_new_cstr(mrb, result_str);

  free(result_str);

  return result;
}

void
mrb_mruby_bnet_authenticator_gem_init(mrb_state* mrb)
{
  struct RClass *bnet_module = mrb_define_module(mrb, "Bnet");
  struct RClass *rsa_helper_class = mrb_define_module_under(mrb, bnet_module, "Util");
  mrb_define_class_method(mrb, rsa_helper_class, "mod_exp", mrb_mod_exp, MRB_ARGS_REQ(3));
}

void
mrb_mruby_bnet_authenticator_gem_final(mrb_state* mrb)
{
}
