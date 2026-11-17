# Alinhamentos recebidos

| ID | Arquivo | Alinhamento | Extensão geométrica | Estaca inicial declarada | Sistema declarado |
|---|---|---|---:|---:|---|
| GO236 | `GO236.xml` | `20261027_EIXO_GO236_R` | 63.377,034 m | 0+000 | SIRGAS / SA-SIR-23S, UTM zona 23S |
| GO110 | `GO110.xml` | `Eixo_Principal_GO110` | 14.914,221 m | 1+500 | SIRGAS2000 / UTM23S |

## Verificações antes de usar o GPS

- O GO-110 declara duas equações de estaca; a implementação precisa interpretar `StaEquation` e validar o resultado contra referências conhecidas.
- Os primeiros pares de coordenadas sugerem ordens diferentes entre os XML: GO-236 começa por valores próximos de northing e depois easting; GO-110 começa por easting e depois northing. Essa leitura é inferida pela faixa numérica, não é confirmação do projetista.
- Confirmar a ordem X/Y, datum/projeção e unidades com o responsável pelo projeto ou exportação no Civil 3D antes de habilitar a estaca automática.
- O GPS do celular fornece latitude/longitude; o app deverá transformar essas coordenadas para o sistema do eixo e apresentar precisão estimada do GPS.
- O GO-110 é trecho parcial. Não extrapolar estacas para fora da geometria fornecida.

Os valores acima vêm dos metadados LandXML. A extensão geométrica não substitui a validação de equações de estaca, coordenadas, alinhamento e datum.

