
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Kit Resina Epóxi A+B 700g', NULL, 24.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/kit-componente-a-b-resina-epoxi-de-alta-espessura-700-gr-89209632.html', 'Kit A+B resina epóxi alta espessura 700g'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Kit Resina Epóxi A+B 700g' AND brand_name IS NULL);
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Tinta Interior Acetinada Branco Seda 15L', 'Robbialac', 129.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/tinta-de-interior-acetinada-branco-seda-15l-robbialac-81867142.html', 'Tinta interior acetinada branco seda 15L'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Tinta Interior Acetinada Branco Seda 15L' AND brand_name='Robbialac');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Tinta Dyrup Branca Mate 15L', 'Dyrup', 119.90, 'EUR', 'unit', 'https://www.maxmat.pt/pt/dyrup/tinta-003-dyrup-interior-exterior-branca-mate-15l-+-20_p33599.html?id=5&cat=0&pc=1&cbid=229&cbida=2&b=1', 'Tinta interior/exterior branca mate 15L'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Tinta Dyrup Branca Mate 15L' AND brand_name='Dyrup');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Massa Resina de Poliéster 250g', 'Dupli-Color', 7.90, 'EUR', 'unit', 'https://www.maxmat.pt/pt/dupli-color/massa-resina-de-poliester-250g_p9522.html?id=36&cat=0&pc=1', 'Massa de poliéster 250g'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Massa Resina de Poliéster 250g' AND brand_name='Dupli-Color');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Spray Multissuperfícies Dourado Metalizado 0.4L', 'Rust-Oleum', 14.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/spray-multisuperficies-rust-0-4l-dourado-metalizado-16876083.html', 'Spray dourado metalizado 0.4L'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Spray Multissuperfícies Dourado Metalizado 0.4L' AND brand_name='Rust-Oleum');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Spray Anti-Ferrugem Verde Brilhante 400ml', 'Luxens', 9.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/spray-anti-ferrugem-luxens-verde-brilhante-400ml-82992598.html', 'Spray anti-ferrugem verde brilhante 400ml'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Spray Anti-Ferrugem Verde Brilhante 400ml' AND brand_name='Luxens');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Spray Multissuperfícies Preto Mate 400ml', NULL, 8.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/spray-multisuperficies-preto-mate-400ml-83184305.html', 'Spray multissuperfícies preto mate 400ml'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Spray Multissuperfícies Preto Mate 400ml' AND brand_name IS NULL);
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Conjunto 2 Colas Montagem 2x300ml', 'Ceys', 12.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/conjunto-2-colas-montagem-2-x-300-ml-montack-profissional-ceys-16980390.html', 'Conjunto 2 colas montagem Montack Profissional 2x300ml'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Conjunto 2 Colas Montagem 2x300ml' AND brand_name='Ceys');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Cola Fixação Sem Pregos 440g', 'UHU', 6.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/cola-fixacao-sem-pregos-sancas-e-rodapes-interior-440-gr-uhu-14859453.html', 'Cola de fixação sem pregos 440g'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Cola Fixação Sem Pregos 440g' AND brand_name='UHU');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Cola Vinílicos/Alcatifas C20 Rayt 1kg', 'Rayt', 11.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/cola-vinilicos-alcatifas-primacola-c20-rayt-1kg-17921323.html', 'Cola vinílicos/alcatifas C20 1kg'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Cola Vinílicos/Alcatifas C20 Rayt 1kg' AND brand_name='Rayt');
INSERT INTO "FinishingMaterial"(name,brand_name,default_unit_cost,currency,unit_of_measurement,purchase_link,description)
SELECT 'Cola Branca para Madeira 100g', 'Axton', 3.90, 'EUR', 'unit', 'https://www.leroymerlin.pt/produtos/cola-branca-para-madeira-axton-100gr-90111000.html', 'Cola branca madeira 100g'
WHERE NOT EXISTS (SELECT 1 FROM "FinishingMaterial" WHERE name='Cola Branca para Madeira 100g' AND brand_name='Axton');