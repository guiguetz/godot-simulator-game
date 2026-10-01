# 004 — Caixa de andabilidade maior que o tile

- **Status:** Aberto (melhoria / risco)
- **Severidade:** Baixa/Média
- **Sintoma:** o player pode "travar" em cantos/quinas de tiles não-andáveis
  (água, bordas do mapa), pois o teste de andabilidade usa uma caixa maior que
  um tile.

## Causa

`scripts/player.gd`:

```gdscript
func _area_walkable(center: Vector2) -> bool:
    var feet_center := center + Vector2(0.0, -3.0)
    var half := Vector2(5.0, 3.0) + Vector2(collision_padding, collision_padding)
    ...
```

Com o valor padrão `collision_padding = 4.0`, a meia-largura fica
`(5 + 4, 3 + 4) = (9, 7)`, ou seja, uma caixa de **18x14 px** — maior que o
tile de 16 px. Isso pode fazer o player parar antes do esperado ao passar
perto de um tile bloqueado, sobretudo em movimento diagonal/horizontal.

`_block_unwalkable()` também trata o eixo bloqueado de forma que, se a caixa
expandida invadir um tile não-andável, o eixo correspondente é zerado.

## Correção sugerida (não aplicada)

- Reduzir o `collision_padding` padrão (ex.: `1.5`–`2.0`) e/ou
- Limitar a meia-largura para no máximo meio tile (`8 px`), e/ou
- Trocar a checagem por uma amostragem em cruz (centro + 4 pontos) em vez dos
  cantos da caixa expandida.

## Por que não corrigido agora

É um ajuste de *feel* de gameplay; alterar sem feedback muda o comportamento de
colisão em todo o mapa. Fica registrado para quando houver teste jogável.
