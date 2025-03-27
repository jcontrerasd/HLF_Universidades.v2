/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const registroAlumnos = require('./lib/registroAlumnos');

module.exports.registroAlumnos = registroAlumnos;
module.exports.contracts = [registroAlumnos];
