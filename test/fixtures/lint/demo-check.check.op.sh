#!/usr/bin/env bash

:<<'DOC'
A minimal check plugin the registry tests load from a copied-in path.
DOC
@check.demo-check() {
  @summary() {
    printf 'A demo.\n'
  }

  @languages() {
    @arr jq
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf 'Demo it.\n'
  }

  @run() {
    :
  }
}
