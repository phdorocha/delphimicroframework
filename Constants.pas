unit Constants;

interface

const
  INI_BASECONHECIMENTO: String = 'https://baseconhecimento.sidsolucoes.com.br/index.php?title=';
  URL_RDWEasy = 'http://easyvendasweb.com.br:8085';
  // sessão
  INI_SESSAO_CORES: String = 'COLORS';
  INI_SESSAO_PAGINA: String = 'Pagina';
  INI_SESSAO_CONFIG: String = 'Config';
  INI_SESSAO_CONEXAO: String = 'Conexao';
  INI_KEYS_VERSAO: String = 'Versao';
  INI_SESSAO_LOG: String = 'LOG';
  INI_SESSAO_DADOS: String = 'Dados';
  INI_SESSAO_POSICAO: string = 'Posicao';
  INI_SESSAO_NFE: String = 'NFe';
  INI_SESSAO_NFCE: String = 'NFCe';
  INI_PDV_BALANCA: String = 'Balanca';
  INI_SESSAO_FDCON: String = 'FDConnection';

  // Informações de Banco
  LOG_LOG_BD: String = 'PathBDLog'; { Banco Log }
  LOG_SENHA_BD: String = 'Psw'; { Senha banco log }
  INI_BD: String = 'CaminhoBD'; { Banco dados }
  INI_PSWDB: String = 'PswDB'; { Senha banco dados }
  INI_BD_IMG: String = 'PathBDImg'; { Banco imagnes }
  INI_ADIVISOR: String = 'Adivisor'; { Código criptografia }
  INI_BD_IP: String = 'BDIP';
  INI_LOGIN: String = 'Login';

  // SQL SERVER
  INI_SERVER   : String = 'Server';
  INI_INSTANCIA: String = 'Instancia';
  INI_ONLOGIN  : String = 'OnLogin';
  INI_ONSENHA  : String = 'OnSenha';

  // Rest Dataware
  INI_USUARIODW: String = 'UsuarioDW';
  INI_SENHADW  : String = 'SenhaDW';

  // Servidor DataSnap
  INI_SERVICO :  String = 'Servico';
  INI_BD_PORTA:  String = 'Porta';
  INI_RDW_PORTA: String = 'Porta';

  // Dados
  INI_USERCH: String = 'UserCh';
  INI_CHECK : String = 'Check';
  INI_CAIXA : String = 'Caixa';

  // Versão
  INI_Local  : String = 'Local';
  INI_Remoto : String = 'Remoto';
  INI_SISTEMA: String = 'Sistema';
  INI_CLINET : String = 'CliNet';
  INI_SYSNET : String = 'SysNet';
  INI_URLKEY : String = 'URLKey';

  // Config
  INI_SKIN: String = 'Skin';
  INI_LOGO: String = 'Logo';
  INI_RODAPE1: String = 'Rodape1';
  INI_RODAPE2: String = 'Rodape2';
  INI_RODAPE3: String = 'Rodape3';
  INI_UPDATE: String = 'AutoApdate';
  INI_AUTORUN: String = 'Autorun';
  INI_LAYOUT: String = 'Layout';
  INI_LAYREST: String = 'LayoutMesas';
  INI_PATHTMP: String = 'PathTmp';
  INI_PATHINTEG: String = 'PathInteg';
  INI_COMPACT: String = 'Compactar';
  INI_FTPDIR: String = 'FTPDir';

  // Caminho para atualização
  INI_PATHSERV: String = 'PathServ';
  INI_PATHEXE: String = 'PathExe';

  // Balanca
  INI_PDV_CHAVE_MARCA: String = 'Marca';
  INI_PDV_CHAVE_MODELO: String = 'Modelo';
  INI_PDV_CHAVE_VELOCIDADE: String = 'Velocidade';
  INI_PDV_CHAVE_HANDSHAKE: String = 'HandShake';
  INI_PDV_CHAVE_PARITY: String = 'Parity';
  INI_PDV_CHAVE_STOP: String = 'Stop';
  INI_PDV_CHAVE_DATA: String = 'Data';
  INI_PDV_CHAVE_BAUDRATE: String = 'BaudRate';
  INI_PDV_CHAVE_PORTA: String = 'Porta';

  // keys
  INI_KEYS_CONTROLS: String = 'CONTROLS';
  INI_KEYS_FORMS: String = 'FORMS';
  INI_KEYS_FONTS: String = 'FONTS';

  // EasyTemplo
  INI_CONFIG_ORDINARIAN = 'OrdinariaN';

  // EasyRelatorioVX
  INI_CONFIG_DIRVX: string    = 'DirVX';
  INI_CONFIG_DIRJOB: string   = 'DirJob';
  INI_CHQ_IMPPORT: string     = 'ImpPort';
  INI_CHQ_LFIMPAG: string     = 'LFimPag';
  INI_CHQ_LINIPAG: string     = 'LIniPag';
  INI_CHQ_TAMANHO: string     = 'Tamanho';
  INI_CHQ_PVALOR:  string     = 'pValor';
  INI_CHQ_PVLREXTENSO: string = 'pVlrExtenso';
  INI_CHQ_PNOMINAL: string    = 'pNominal';
  INI_CHQ_PCIDADE: string     = 'pCidade';
  INI_CHQ_PDIA: string        = 'pDia';
  INI_CHQ_PMES: string        = 'pMes';
  INI_CHQ_PANO: string        = 'pAno';

  // ExportaOpenCart
  INI_OC_INTEGRA: string = 'Integra';
  INI_OC_HOSTNAME: string = 'HostName';
  INI_OC_BDNOME: string = 'BdNome';
  INI_OC_USER_NAME: string = 'User_Name';
  INI_OC_PASSWORD: string = 'Key';
  INI_OC_PREF_TABLE: string = 'Oc_pref_table';
  INI_OC_STORE_ID: string = 'Store_id';
  INI_OC_LAYOUT_ID: string = 'Layout_id';
  INI_OC_LANGUAGE_ID: string = 'Language_id';
  INI_OC_PEDDTINI: string = 'PedidoDtIni';
  INI_OC_PEDDTFIM: string = 'PedidoDtFim';

  { Configurações da NF-e }
  INI_NFE_FUSOHORARIO: String = 'FusoHorario';
  INI_NFE_EMPRESAID: String = 'EmpresaID';

  { Integração PedidoOk Fit }
  INI_POF_REPRES_ID: String = 'RepresentadaID';

implementation

end.
