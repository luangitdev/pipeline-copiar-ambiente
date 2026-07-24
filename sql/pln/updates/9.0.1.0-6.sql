            --9.0.1.0-6
                ALTER TABLE avisosistema ADD column IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT TRUE;
                ALTER TABLE avisosistema ADD column IF NOT EXISTS naomostrarusuario TEXT;

				DELETE FROM avisosistema WHERE assunto = 'Novo projeto Torre planner + App Mobile ';

                INSERT INTO avisosistema(assunto, atualizado, aviso, criacao,ativo) VALUES ( 'Novo projeto Torre planner + App Mobile ',  now(),'<div class="promo-container" style="display:flex; flex-wrap:wrap; gap:24px; align-items:flex-start; text-align: left">
                    <!-- Coluna esquerda: texto -->
                    <div style="flex:1 1 380px; min-width:300px;">
                        <span style="display:inline-block; background:#eaf3ff; color:#1b5eaa; padding:6px 10px; border-radius:12px; font-weight:600; margin-bottom:32px; display: flex; align-items: center; width:160px"><img style="width: 30px; height: 25px" src="../../pages/images/aviso/icone_foguete.png">Novo Produto</span>
                        <h2 style="margin:0 0 8px 0; color:#21407b;">Torre Planner + App Mobile:</h2>
                        <h3 style="margin:0 0 16px 0; color:#1b5eaa; font-weight:700;">o comando completo da sua equipe em campo.</h3>
                        <p>Do planejamento à execução, <strong>gere insights a cada movimento</strong>. Controle rotas, acompanhe o desempenho e conecte suas operações de campo em tempo real com a Pathfind.</p></br></br>
                        <ul style="padding-left: 18px; list-style: none; padding: 0; ">
                            <li style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;"><img style="width: 30px; height: 25px" src="../../pages/images/aviso/icone_seta_torta.png"> Planejamento inteligente de rotas</li></br>
                            <li style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;"><img style="width: 30px; height: 25px" src="../../pages/images/aviso/icone_seta_torta.png"> Acompanhamento de desempenho da equipe</li></br>
                            <li style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;"><img style="width: 30px; height: 25px" src="../../pages/images/aviso/icone_seta_torta.png"> Acompanhe KPIs de produtividade da equipe</li></br>
                            <li style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;"><img style="width: 30px; height: 25px" src="../../pages/images/aviso/icone_seta_torta.png"> Monitore em tempo real a localização, o status e o desempenho de cada vendedor</li></br>
                        </ul></br></br>
                        <div style="margin-top: 18px; text-align: center">
                            <a href="https://www.mobiis.com.br/logistica/planner-de-vendas" target="_blank"
                               style="
                                  display: inline-block;
                                  background-color: #1f4b8f;
                                  color: #fff;
                                  font-weight: 600;
                                  text-decoration: none;
                                  padding: 12px 40px;
                                  border-radius: 6px;
                                  text-align: center;
                                  transition: background-color 0.3s, transform 0.2s;
                                  width: 100%;
                               "
                               onmouseover="this.style.backgroundColor=''#2a5cb8''; this.style.transform=''translateY(-2px)''"
                               onmouseout="this.style.backgroundColor=''#1f4b8f''; this.style.transform=''translateY(0)''">
                               Quero saber mais
                            </a>
                        </div>
                    </div>
                    <!-- Coluna direita: vídeo -->
                    <div style="flex:1 1 420px; min-width:300px; background:#eaf3ff; border-radius:12px; padding:12px;">
                        <div style="width:100%; border-radius:8px; overflow:hidden;">
                            <img id="imagem"
                                 src="../../pages/images/aviso/1.png"
                                 alt="Carrossel"
                                 style="display:block; width:100%; height:auto;"/>
                        </div>
                    </div>

                    <script>
                        const imagens = [
                            "../../pages/images/aviso/1.png",
                            "../../pages/images/aviso/2.png",
                            "../../pages/images/aviso/3.png",
                            "../../pages/images/aviso/4.png",
                            "../../pages/images/aviso/5.png",
                        ];
                        let i = 0;
                        setInterval(() => {
                            i = (i + 1) % imagens.length;
                            document.getElementById("imagem").src = imagens[i];
                        }, 1000); // troca a cada 1 segundos
                    </script>
                </div>', now(),true);

				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.1.0-6')
				ON CONFLICT (versao)
				DO NOTHING;