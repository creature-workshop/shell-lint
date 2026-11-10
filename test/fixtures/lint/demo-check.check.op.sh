#!/usr/bin/env bash

:<<'DOC'
A minimal check plugin the registry tests load from a copied-in path.
DOC
@check.demo-check() {
  @summary() {
    printf 'A demo.\n'
  }

  @languages() {
    @arr __at_out jq
    println "$__at_out"
  }

  @scopes() {
    @arr __at_out code
    println "$__at_out"
  }

  @hint() {
    printf 'Demo it.\n'
  }

  @run() {
    :
  }
}
