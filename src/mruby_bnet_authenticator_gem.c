#include <stdlib.h>
#include <stdint.h>
#include "mruby.h"
#include "mruby/string.h"
#include "mruby/array.h"
#include "mruby/value.h"
#include "bigd.h"

static mrb_value
mrb_mod_exp(mrb_state *mrb, mrb_value self)
{
  mrb_value value, exp, mod;
  const char *v_str, *exp_str, *mod_str;
  BIGD v_bd, exp_bd, mod_bd, result_bd;
  size_t nchars;
  char *result_str;
  mrb_value result;

  mrb_get_args(mrb, "SSS", &value, &exp, &mod);

  v_str = mrb_string_value_cstr(mrb, &value);
  exp_str = mrb_string_value_cstr(mrb, &exp);
  mod_str = mrb_string_value_cstr(mrb, &mod);

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

  nchars = bdConvToHex(result_bd, NULL, 0);
  result_str = malloc(nchars + 1);
  bdConvToHex(result_bd, result_str, nchars + 1);

  bdFree(&result_bd);

  result = mrb_str_new_cstr(mrb, result_str);

  free(result_str);

  return result;
}

#ifndef MRB_INT16
static mrb_value
mrb_uint32_split_to_uint16_be(mrb_state *mrb, mrb_value self)
{
  uint32_t input;
  mrb_value list[2];

  mrb_get_args(mrb, "i", &input);

  list[0] = mrb_fixnum_value((input & 0xffff0000) >> 16);
  list[1] = mrb_fixnum_value((input & 0x0000ffff) >> 0);

  return mrb_ary_new_from_values(mrb, 2, list);
}
#endif

void
mrb_mruby_bnet_authenticator_gem_init(mrb_state* mrb)
{
  struct RClass *bnet_module, *util_class;

  bnet_module = mrb_define_module(mrb, "Bnet");
  util_class = mrb_define_module_under(mrb, bnet_module, "Util");

  mrb_define_class_method(mrb, util_class, "mod_exp", mrb_mod_exp, MRB_ARGS_REQ(3));

#ifndef MRB_INT16
  mrb_define_class_method(mrb, util_class, "unit32_split_to_unit16_be", mrb_uint32_split_to_uint16_be, MRB_ARGS_REQ(1));
#endif
}

void
mrb_mruby_bnet_authenticator_gem_final(mrb_state* mrb)
{
}
