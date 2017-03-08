meta:
  id: tasty-eager
  file-extension: tasty
  endian: be
  ks-version: 0.7
seq:
  - id: magic
    contents: [0x5C, 0xA1, 0xAB, 0x1F]
  - id: major_version
    type: nat
  - id: minor_version
    type: nat
  - id: uuid
    size: 16
  - id: name_table_length
    type: nat
  - id: name_table
    type: name_table
    size: name_table_length.value
  - id: sections
    type: section
    repeat: eos
types:
  nat:
    seq:
    - id: groups
      type: nat_byte
      repeat: until
      repeat-until: not _.has_next
    instances:
      last:
        value: groups.size - 1
      value:
        value: >-
          groups[last].value
          + (last >= 1 ? (groups[last - 1].value << 7) : 0)
          + (last >= 2 ? (groups[last - 2].value << 14) : 0)
          + (last >= 3 ? (groups[last - 3].value << 21) : 0)
          + (last >= 4 ? (groups[last - 4].value << 28) : 0)
          + (last >= 5 ? (groups[last - 5].value << 35) : 0)
          + (last >= 6 ? (groups[last - 6].value << 42) : 0)
          + (last >= 7 ? (groups[last - 7].value << 49) : 0)
  nat_byte:
    seq:
      - id: b
        type: u1
    instances:
      has_next:
        value: (b & 128) == 0
      value:
        value: b & 0b0111_1111
  name_table:
   seq:
    - id: entries
      type: name_table_entry
      repeat: eos
  name_table_entry:
   seq:
    - id: type
      type: u1
      enum: name_tag
    - id: length
      type: nat
    - id: body
      size: length.value
      type:
        switch-on: type
        cases:
          name_tag::utf8         : name_utf8
          name_tag::qualified    : name_qualified
          name_tag::signed       : name_signed
          name_tag::expanded     : name_expanded
          name_tag::objectclass  : name_object_class
          name_tag::superaccessor: name_super_accessor
          name_tag::defaultgetter: name_default_getter
          name_tag::shadowed     : name_shadowed
  name_ref:
    seq:
     - id: ref_id
       type: nat
    instances:
     value:
       value: _root.name_table.entries[ref_id.value]
  ast_ref:
    seq:
     - id: ref_id
       type: nat # todo: make it read from stream
  name_utf8:
    seq:
     - id: str
       size-eos: true
       type: str
       encoding: UTF-8
  name_qualified:
    seq:
     - id: qualified_ref
       type: name_ref
     - id: selector_ref
       type: name_ref
  name_signed:
    seq:
     - id: original_nameref
       type: name_ref
     - id: resultsig_nameref
       type: name_ref
     - id: paramsig_name
       type: name_ref
       repeat: eos
  name_expanded:
    seq:
     - id: original_nameref
       type: name_ref
  name_object_class:
    seq:
     - id: object_nameref
       type: name_ref
  name_super_accessor:
    seq:
     - id: accessed_nameref
       type: name_ref
  name_default_getter:
    seq:
     - id: methodname
       type: name_ref
     - id: param_number
       type: nat
  name_shadowed:
    seq:
     - id: origial_nameref
       type: name_ref
  section:
    seq:
     - id: name
       type: name_ref
     - id: length
       type: nat
     - id: data
       size: length.value
       type:
         switch-on: name.value.body.as<name_utf8>.str
         cases:
          '"ASTs"' : section_ast
          '"Positions"' : section_positions
  section_ast:
    seq:
     - id: trees
       type: ast_tree
       repeat: eos
  section_positions:
    seq:
     - id: positions
       size-eos: true
  # cat5 trees:
  ast_package:
    seq:
     - id: path
       type: ast_tree
     - id: stats
       type: ast_tree
       repeat: eos
  ast_valdef:
    seq:
     - id: name
       type: name_ref
     - id: type
       type: ast_tree
     - id: rhs_and_modifiers
       type: ast_tree
       repeat: eos
  ast_defdef:
    seq:
     - id: name
       type: name_ref
     - id: typeparam_params_return_rhs_mod
       type: ast_tree
       repeat: eos # todo: this is a hack
  ast_typedef:
    seq:
     - id: name
       type: name_ref
     - id: type_or_template
       type: ast_tree
     - id: modifiers
       type: ast_tree
       repeat: eos
  ast_import:
    seq:
     - id: qual
       type: ast_tree
     - id: selectors
       type: ast_tree
       repeat: eos
  ast_imported:
    seq:
     - id: name
       type: name_ref
  ast_renamed:
    seq:
     - id: to
       type: name_ref
  ast_typeparam:
    seq:
     - id: name
       type: name_ref
     - id: type
       type: ast_tree
     - id: modifiers
       type: ast_tree
       repeat: eos
  ast_params:
    seq:
     - id: params
       type: ast_tree
       repeat: eos
  ast_param:
    seq:
     - id: name
       type: name_ref
     - id: type
       type: ast_tree
     - id: rhs_modifiers
       type: ast_tree
       repeat: eos
  ast_template:
    seq:
     - id: typeparam_param_parent_self_stat
       type: ast_tree
       repeat: eos
  ast_selfdef:
    seq:
      - id: name
        type: name_ref
      - id: type
        type: ast_tree
  ast_ident:
    seq:
      - id: name
        type: name_ref
      - id: type
        type: ast_tree
  ast_ident_tpt:
    seq:
      - id: name
        type: name_ref
      - id: type
        type: ast_tree
  ast_select:
    seq:
      - id: sel
        type: name_ref
      - id: qual
        type: ast_tree
  ast_select_tpt:
    seq:
      - id: sel
        type: name_ref
      - id: qual
        type: ast_tree
  ast_new:
    seq:
      - id: cls_type
        type: ast_tree
  ast_super:
    seq:
     - id: this_term
       type: ast_tree
     - id: mixin
       type: ast_tree
       repeat: eos
  ast_typed:
    seq:
     - id: expr
       type: ast_tree
     - id: ascription
       type: ast_tree
  ast_namedarg:
    seq:
     - id: param_name
       type: name_ref
     - id: arg
       type: ast_tree
  ast_assign:
    seq:
     - id: lhs
       type: ast_tree
     - id: rhs
       type: ast_tree
  ast_block:
    seq:
     - id: expr
       type: ast_tree
     - id: stats
       type: ast_tree
       repeat: eos
  ast_if:
    seq:
     - id: cond
       type: ast_tree
     - id: then
       type: ast_tree
     - id: else
       type: ast_tree
  ast_lambda:
    seq:
     - id: meth
       type: ast_tree
     - id: target
       type: ast_tree
     - id: env
       type: ast_tree
       repeat: eos
  ast_match:
    seq:
     - id: sel
       type: ast_tree
     - id: cases
       type: ast_tree
       repeat: eos
  ast_return:
    seq:
     - id: method
       type: ast_tree
     - id: expr
       type: ast_tree
       doc: "Returns unit if absent"
       repeat: eos
  ast_try:
    seq:
     - id: expr
       type: ast_tree
     - id: casedefs_finalizer
       type: ast_tree
       repeat: eos
  ast_repeated:
    seq:
     - id: elem_type
       type: ast_tree
     - id: elems
       type: ast_tree
       repeat: eos
  ast_bind:
    seq:
     - id: bound_name
       type: name_ref
     - id: pat_type
       type: ast_tree
     - id: pat_term
       type: ast_tree
  ast_alternative:
    seq:
     - id: alts
       type: ast_tree
       repeat: eos
  ast_unapply:
    seq:
     - id: fun
       type: ast_tree
     - id: implicitargs_pattpe_pat
       type: ast_tree
       repeat: eos
  ast_apply:
    seq:
     - id: fun
       type: ast_tree
     - id: args
       type: ast_tree
       repeat: eos
  ast_typeapply:
    seq:
     - id: fun
       type: ast_tree
     - id: args
       type: ast_tree
       repeat: eos
  ast_casedef:
    seq:
     - id: pat
       type: ast_tree
     - id: rhs
       type: ast_tree
     - id: guard
       type: ast_tree
       repeat: eos
  ast_implicit_arg:
   seq:
     - id: arg
       type: ast_tree
  ast_termref_direct:
   seq:
     - id: sym
       type: ast_ref
  ast_rec_this:
    seq:
     - id: type
       type: ast_ref
  ast_termref_symbol:
   seq:
     - id: sym
       type: ast_ref
     - id: qual
       type: ast_tree
  ast_termref_pkg:
    seq:
     - id: name
       type: name_ref
  ast_termref:
    seq:
     - id: sel
       type: name_ref
     - id: qual
       type: ast_tree
  ast_typeref_direct:
   seq:
     - id: sym
       type: ast_ref
  ast_typeref_symbol:
   seq:
     - id: sym
       type: ast_ref
     - id: qual
       type: ast_tree
  ast_typeref_pkg:
    seq:
     - id: name
       type: name_ref
  ast_typeref:
    seq:
     - id: sel
       type: name_ref
     - id: qual
       type: ast_tree
  ast_this:
    seq:
     - id: cls
       type: ast_tree
  ast_qual_this:
    seq:
     - id: qual
       type: ast_tree
  ast_rec_type:
    seq:
     - id: ref
       type: ast_ref
  ast_shared:
    seq:
     - id: ref
       type: ast_ref

  ast_unit_const:
    doc: "()"
  ast_false_const:
    doc: "false"
  ast_true_const:
    doc: "true"
  ast_private: 
    doc: "private"
  ast_internal:
    doc: "internal"
  ast_protected:
    doc: "protected"
  ast_abstract:
    doc: "abstract"
  ast_final:
    doc: "final"
  ast_sealed:
    doc: "sealed"
  ast_case:
    doc: "case"
  ast_lazy:
    doc: "lazy"
  ast_implicit:
    doc: "implicit"
  ast_override:
    doc: "override"
  ast_inline:
    doc: "inline"
  ast_static:
    doc: "static"
  ast_object:
    doc: "object"
  ast_trait:
    doc: "trait"
  ast_local:
    doc: "local"
  ast_synthetic:
    doc: "synthetic"
  ast_artifact:
    doc: "artifact"
  ast_mutable:
    doc: "mutable"
  ast_label:
    doc: "label"
  ast_field_accessor:
    doc: "field_accessor"
  ast_case_accessor:
    doc: "case_accessor"
  ast_covariant:
    doc: "covariant"
  ast_contravariant:
    doc: "contravariant"
  ast_scala2x:
    doc: "scala2x"
  ast_default_parameterized:
    doc: "default_parameterized"
  ast_in_supercall:
    doc: "in_supercall"
  ast_stable:
    doc: "stable"
  ast_byte_const:
    seq:
     - id: value
       type: nat
  ast_short_const:
    seq:
     - id: value
       type: nat
  ast_char_const:
    seq:
     - id: value
       type: nat
  ast_int_const:
    seq:
     - id: value
       type: nat
  ast_long_const:
    seq:
     - id: value
       type: nat
  ast_float_const:
    seq:
     - id: value
       type: nat
  ast_double_const:
    seq:
     - id: value
       type: nat
  ast_string_const:
    seq:
     - id: value
       type: name_ref
  ast_null_const:
    doc: "null"
  ast_class_const:
    seq:
     - id: value
       type: ast_tree
  ast_enum_const:
    seq:
     - id: value
       type: ast_tree
  ast_byname_type:
    seq:
     - id: type
       type: ast_tree
  ast_byname_tpt:
    seq:
     - id: type
       type: ast_tree 
  ast_private_qualified:
    seq:
     - id: qual
       type: ast_tree 
  ast_protected_qualified:
    seq:
     - id: qual
       type: ast_tree 
  ast_singleton_tpt:
    seq:
     - id: singleton
       type: ast_tree 
  ast_annotation:
    seq:
     - id: annot
       type: ast_tree
     - id: expr
       type: ast_tree
  ast_cat5_or_unknown:
    seq:
     - id: cat2_nat
       if: (_parent.tag >= 64) and (_parent.tag < 96)
       type: nat
     - id: cat3_ast
       if: (_parent.tag >= 96) and (_parent.tag < 112)
       type: ast_tree
     - id: cat4_nat
       if: (_parent.tag >= 112) and (_parent.tag < 128)
       type: nat
     - id: cat4_ast
       if: (_parent.tag >= 112) and (_parent.tag < 128)
       type: ast_tree
     - id: cat5_length
       if: (_parent.tag >= 128)
       type: nat
     - id: cat5_tree
       if: (_parent.tag >= 128) and (_parent.tag < 175)
       size: cat5_length.value
       type:
          switch-on: _parent.tag
          cases:
            # cat5
            ast_tag::package        : ast_package
            ast_tag::valdef         : ast_valdef
            ast_tag::defdef         : ast_defdef
            ast_tag::typedef        : ast_typedef
            ast_tag::import         : ast_import
            ast_tag::typeparam      : ast_typeparam
            ast_tag::params         : ast_params
            ast_tag::param          : ast_param
            ast_tag::apply          : ast_apply
            ast_tag::typeapply      : ast_type_apply #
            ast_tag::typed          : ast_typed
            ast_tag::namedarg       : ast_namedarg #
            ast_tag::assign         : ast_assign
            ast_tag::block          : ast_block
            ast_tag::if             : ast_if
            ast_tag::lambda         : ast_lambda #
            ast_tag::match          : ast_match
            ast_tag::return         : ast_return
            ast_tag::try            : ast_try
            ast_tag::inlined        : ast_inlined #
            ast_tag::repeated       : ast_repeated
            ast_tag::bind           : ast_bind
            ast_tag::alternative    : ast_alternative
            ast_tag::unapply        : ast_unapply
            ast_tag::annotated_type : ast_annotated_type #
            ast_tag::annotated_tpt  : ast_annotated_tpt #
            ast_tag::casedef        : ast_casedef
            ast_tag::template       : ast_template
            ast_tag::super          : ast_super
            ast_tag::super_type     : ast_super_type #
            ast_tag::refiend_type   : ast_refined_type #
            ast_tag::refined_tpt    : ast_refined_tpt #
            ast_tag::applied_type   : ast_applied_type #
            ast_tag::applied_tpt    : ast_applied_tpt #
            ast_tag::typebounds     : ast_typebounds #
            ast_tag::typeboundstpt  : ast_typeboundstpt #
            ast_tag::typealias      : ast_typealias #
            ast_tag::and_type       : ast_and_type #
            ast_tag::and_tpt        : ast_and_tpt #
            ast_tag::or_type        : ast_or_type #
            ast_tag::or_tpt         : ast_or_tpt #
            ast_tag::method_type    : ast_method_type #
            ast_tag::poly_type      : ast_poly_type #
            ast_tag::poly_tpt       : ast_poly_tpt #
            ast_tag::param_type     : ast_param_type #
            ast_tag::annotation     : ast_annotation
     - id: cat5_payload
       if: (_parent.tag >= 175)
       size: cat5_length.value
  ast_tree:
    seq:
     - id: tag
       type: u1
#       enum: ast_tag
     - id: decoded
       type:
          switch-on: tag
          cases:
            #cat1
            ast_tag::unit_const    : ast_unit
            ast_tag::false_const   : ast_false
            ast_tag::true_const    : ast_true
            ast_tag::null_const    : ast_null
            ast_tag::private       : ast_private 
            ast_tag::internal      : ast_internal 
            ast_tag::protected     : ast_protected 
            ast_tag::abstract      : ast_abstract 
            ast_tag::final         : ast_final  
            ast_tag::sealed        : ast_sealed 
            ast_tag::case          : ast_case 
            ast_tag::implicit      : ast_implicit 
            ast_tag::lazy          : ast_lazy  
            ast_tag::override      : ast_override 
            ast_tag::inline        : ast_inline 
            ast_tag::static        : ast_static 
            ast_tag::object        : ast_object 
            ast_tag::trait         : ast_trait 
            ast_tag::local         : ast_local 
            ast_tag::synthetic     : ast_synthetic 
            ast_tag::artifact      : ast_artifact 
            ast_tag::mutable       : ast_mutable 
            ast_tag::label         : ast_label 
            ast_tag::field_accessor: ast_field_accessor 
            ast_tag::case_accessor : ast_case_case_accessor 
            ast_tag::covariant     : ast_covariant 
            ast_tag::contravariant : ast_contravariant 
            ast_tag::scala2x       : ast_scala2x 
            ast_tag::default_parameterized : ast_default_parameterized 
            ast_tag::in_supercall  : ast_in_supercall 
            ast_tag::stable        : ast_stable 
            #cat2
            ast_tag::shared         : ast_shared
            ast_tag::termref_direct : ast_termref_direct
            ast_tag::typeref_direct : ast_typeref_direct
            ast_tag::termref_pkg    : ast_termref_pkg
            ast_tag::typeref_pkg    : ast_typeref_pkg
            ast_tag::rec_this       : ast_rec_this
            ast_tag::byte_const     : ast_byte_const
            ast_tag::short_const    : ast_short_const
            ast_tag::char_const     : ast_char_const
            ast_tag::int_const      : ast_int_const
            ast_tag::long_const     : ast_long_const
            ast_tag::float_const    : ast_float_const
            ast_tag::double_const   : ast_double_const
            ast_tag::string_const   : ast_string_const
            ast_tag::imported       : ast_imported
            ast_tag::renamed        : ast_renamed
            # cat3:
            ast_tag::this           : ast_this
            ast_tag::qual_this      : ast_qual_this
            ast_tag::class_const    : ast_class_const
            ast_tag::enum_const     : ast_enum_const
            ast_tag::byname_type    : ast_byname_type
            ast_tag::byname_tpt     : ast_byname_tpt
            ast_tag::new            : ast_new
            ast_tag::implicit_arg   : ast_implicit_arg
            ast_tag::private_qualified   : ast_private_qualified
            ast_tag::protected_qualified : ast_protected_qualified 
            ast_tag::rec_type       : ast_rec_type
            ast_tag::singleton_tpt  : ast_singleton_tpt
            # cat4:
            ast_tag::ident          : ast_ident
            ast_tag::ident_tpt      : ast_ident_tpt
            ast_tag::select         : ast_select
            ast_tag::select_tpt     : ast_select_tpt
            ast_tag::termref_symbol : ast_termref_symbol
            ast_tag::termref        : ast_termref
            ast_tag::typeref_symbol : ast_typeref_symbol
            ast_tag::typeref        : ast_typeref
            ast_tag::selfdef        : ast_selfdef
            # cat5
            _                       : ast_cat5_or_unknown
enums:
  name_tag:
    1: utf8
    2: qualified
    3: signed
    4: expanded
    5: objectclass
    6: superaccessor
    7: defaultgetter
    8: shadowed
  ast_tag:
#costants
    2: unit_const
    3: false_const
    4: true_const
    5: null_const
#flags
    6: private
    7: internal
    8: protected
    9: abstract
    10: final
    11: sealed
    12: case
    13: implicit
    14: lazy
    15: override
    16: inline
    17: static
    18: object
    19: trait
    20: local
    21: synthetic
    22: artifact
    23: mutable
    24: label
    25: field_accessor
    26: case_accessor
    27: covariant
    28: contravariant
    29: scala2x
    30: default_parameterized
    31: in_supercall
    32: stable
#types
    64: shared
    65: termref_direct
    66: typeref_direct
    67: termref_pkg
    68: typeref_pkg
    69: rec_this
    70: byte_const
    71: short_const
    72: char_const
    73: int_const
    74: long_const
    75: float_const
    76: double_const
    77: string_const
    78: imported
    79: renamed
# trees
    96: this
    97: qual_this
    98: class_const
    99: enum_const
    100: byname_type
    101: byname_tpt
    102: new
    103: implicit_arg
    104: private_qualified
    105: protected_qualified
    106: rec_type
    107: singleton_tpt
# trees
    112: ident
    113: ident_tpt
    114: select
    115: select_tpt
    116: termref_symbol
    117: termref
    118: typeref_symbol
    119: typeref
    120: selfdef
# skip
    128: package
    129: valdef
    130: defdef
    131: typedef
    132: import
    133: typeparam
    134: params
#skip
    136: param
    137: apply
    138: typeapply
    139: typed
    140: namedarg
    141: assign
    142: block
    143: if
    144: lambda
    145: match
    146: return
    147: try
    148: inlined
    149: repeated
    150: bind
    151: alternative
    152: unapply
    153: annotated_type
    154: annotated_tpt
    155: casedef
    156: template
    157: super
    158: super_type
    159: refiend_type
    160: refined_tpt
    161: applied_type
    162: applied_tpt
    163: typebounds
    164: typeboundstpt
    165: typealias
    166: and_type
    167: and_tpt
    168: or_type
    169: or_tpt
    170: method_type
    171: poly_type
    172: poly_tpt
    173: param_type
    174: annotation