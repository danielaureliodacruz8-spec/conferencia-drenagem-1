# Conferência de drenagem rodoviária

Repositório organizado com a base de referência para o app de fiscalização de drenagem usado em campo.

## Conteúdo

- `app/prototype-singlefile.html`: protótipo navegável de interface e fluxo.
- `data/source/alignments/`: eixos XML da GO-110 e GO-236.
- `data/processed/`: catálogo de dispositivos e transcrições de referência da drenagem da GO-110.
- `data/processed/projects/GO236/README.md`: mesmos tipos de dispositivos; posições da GO-236 ficam para preenchimento manual até chegar o projeto dessa rodovia.
- `app/public/assets/`: marcas visuais e imagem de exemplo da foto carimbada.
- `docs/`: notas dos alinhamentos, critérios técnicos e estilo de fotos.

## Uso no Android / CodeMagic

Este material é a base organizada e o protótipo visual. A interface HTML ainda precisa ser implementada no app Flutter Android do CodeMagic. Os dados da GO-110 são próprios dessa rodovia e não devem ser usados como localização na GO-236.

## Observações de campo

- A estaca pelo GPS depende de validar o sistema de coordenadas e as equações de estaca do eixo.
- O formulário pode registrar medidas e calcular quantitativos conforme dimensões e fórmulas cadastradas.
- A aprovação precisa comparar medidas com critérios e tolerâncias definidos no projeto; preencher o formulário sozinho não comprova conformidade.
- Os PDFs de origem foram mantidos fora deste repositório; os dados estruturados/transcritos relevantes estão em `data/processed/projects/GO110/`.
