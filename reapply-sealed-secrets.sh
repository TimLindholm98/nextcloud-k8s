#!/bin/bash

for i in $(ls secrets/sealed/*); do kubectl apply -f $i ; done
