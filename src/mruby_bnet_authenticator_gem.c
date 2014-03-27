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

#ifndef MRB_INT16
static mrb_value
mrb_uint32_split_to_uint16_be(mrb_state *mrb, mrb_value self)
{
  uint32_t input = 0;
  mrb_get_args(mrb, "i", &input);

  uint32_t output0 = (input & 0xffff0000) >> 16;
  uint32_t output1 = (input & 0x0000ffff) >> 0;

  mrb_value list[2] = {mrb_fixnum_value(output0), mrb_fixnum_value(output1)};

  return mrb_ary_new_from_values(mrb, 2, list);
}
#endif

void
mrb_mruby_bnet_authenticator_gem_init(mrb_state* mrb)
{
  struct RClass *bnet_module = mrb_define_module(mrb, "Bnet");
  struct RClass *util_class = mrb_define_module_under(mrb, bnet_module, "Util");
  mrb_define_class_method(mrb, util_class, "mod_exp", mrb_mod_exp, MRB_ARGS_REQ(3));

#ifndef MRB_INT16
  mrb_define_class_method(mrb, util_class, "unit32_split_to_unit16_be", mrb_uint32_split_to_uint16_be, MRB_ARGS_REQ(1));
#endif
}

void
mrb_mruby_bnet_authenticator_gem_final(mrb_state* mrb)
{
}
