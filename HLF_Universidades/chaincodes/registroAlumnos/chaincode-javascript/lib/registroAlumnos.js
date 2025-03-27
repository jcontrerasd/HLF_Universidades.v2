/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Contract } = require('fabric-contract-api');

class RegistroAlumnos extends Contract {

    async InitLedger(ctx) {
        const alumnos = [
            {
                nombre: 'Juan Perez',
                universidad: 'Universidad Nacional',
            },
            {
                nombre: 'Laura Martinez',
                universidad: 'Universidad de Los Andes',
            },
            {
                nombre: 'Carlos Lopez',
                universidad: 'Universidad Javeriana',
            },
            {
                nombre: 'Pedro Valencia',
                universidad: 'Universidad de Berlin',
            },
        ];
        for (const alumno of alumnos) {
            alumno.docType = 'alumno';
            await ctx.stub.putState(alumno.nombre, Buffer.from(JSON.stringify(alumno)));
            console.info(`Asset ${alumno.nombre} initialized`);
        }
    }

    async registrarAlumno(ctx, alumnoId, nombre, universidad) {
        console.info('============= START : Registrar Alumno ===========');
        const alumno = {
            docType: 'alumno',
            nombre,
            universidad,
        };
        await ctx.stub.putState(alumnoId, Buffer.from(JSON.stringify(alumno)));
        console.info('============= END : Registrar Alumno ===========');
    }

    async obtenerAlumno(ctx, alumnoId) {
        const alumnoAsBytes = await ctx.stub.getState(alumnoId); // get the alumno from chaincode state
        if (!alumnoAsBytes || alumnoAsBytes.length === 0) {
            throw new Error(`${alumnoId} no existe`);
        }
        console.log(alumnoAsBytes.toString());
        return alumnoAsBytes.toString();
    }

    async obtenerTodosAlumnos(ctx) {
        const allResults = [];
        // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            allResults.push({ Key: result.value.key, Record: record });
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}
module.exports = RegistroAlumnos;
