# delphiframwork
Micro Framework desenvolvido para facilitar a vida do programador Delphi com uma classe prática quando o negócio é SQL.

# Instalação
A forma de usar fica a seu critério, caso queira seguir nossa sugestão, na pasta do seu projeto crie uma pasta de nome Classes, nessa pasta baixe o repositório que terá as pastas Controle e Modulos.

# Utilização

Basta dar uses na classe Controle:

uses
  Controle.SeuControle;
  
Na classe Modulo.SeuModulo, deverá setar TableName que é o nome da sua tabela no banco, PrimaryKey que é a chave primária.
O método FieldDefs define as formatações e demais alterações para os Fields.
O método FieldTitles defina o nome do campo e o título que o mesmo receberá: ACds.FieldTitle('IDPRODUTO', 'Código');
O método DefineColunas defina as colunas que deseja trabalhar (se não definir as consultas serão "select *". As colunas são informadas no array assim:
  SetLength(fillable, 48);
  fillable[0] := UpperCase('IdProduto');
  
Na view basta chamar o método passando por parâmetro um DataSource ligado a um ClientDataSet assim:
  SeuControle.DataSetPesquisar(SeuDataSource);
  
No seu controle esse médoto chamará o método do Module assim:
  seuModulo.Todos([], SeuDataSource);
  
Seu módulo por sua vez chamará o método pai assim:
  AdsAtivo.DataSet := self.All(Columns);
